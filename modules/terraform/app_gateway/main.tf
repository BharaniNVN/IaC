locals {
  location                               = coalesce(var.location, data.azurerm_resource_group.this.location)
  backend_address_pool_unfiltered        = { for i in var.mappings : i["pool_name"] => lookup(i, "servers", [])... }
  backend_address_pool                   = { for k, v in local.backend_address_pool_unfiltered : k => distinct(flatten(v)) }
  mappings_with_probe                    = { for k, v in var.mappings : k => v if lookup(v, "probe_path", null) != null }
  frontend_port_name                     = "${var.resource_prefix}-agw-feport"
  frontend_ip_configuration_name         = "${var.resource_prefix}-agw-feip"
  frontend_private_ip_configuration_name = "${var.resource_prefix}-agw-private-feip"
  key_vault_id                           = { for i in distinct(var.certificates[*].key_vault_id) : basename(i) => i }
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

resource "azurerm_user_assigned_identity" "this" {
  name                = "${var.resource_prefix}-appgateway-uai"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = local.location

  tags = merge(
    var.tags,
    {
      "resource" = "user assigned identity"
    },
  )
}

resource "azurerm_key_vault_access_policy" "this" {
  for_each = local.key_vault_id

  key_vault_id = each.value
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.this.principal_id

  secret_permissions = ["Get"]
}

resource "azurerm_public_ip" "this" {
  count = contains(var.fe_configs, "public") ? 1 : 0

  name                = "${var.resource_prefix}-agw-pip"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.this.name
  allocation_method   = var.agw_tier == "WAF_v2" ? "Static" : "Dynamic"
  domain_name_label   = format("%s%s", var.resource_prefix, var.public_ip_domain_suffix)
  sku                 = var.agw_tier == "WAF_v2" ? "Standard" : "Basic"

  tags = merge(
    var.tags,
    {
      "resource" = "public ip"
    },
  )
}

resource "azurerm_application_gateway" "agw" {
  name                = "${var.resource_prefix}-appgateway"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = local.location

  sku {
    name     = var.agw_sku
    tier     = var.agw_tier
    capacity = var.agw_capacity
  }

  waf_configuration {
    firewall_mode    = var.waf_mode
    rule_set_type    = "OWASP"
    rule_set_version = "3.0"
    enabled          = true
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20170401S"
  }

  gateway_ip_configuration {
    name      = "${var.resource_prefix}-gateway-ip-configuration"
    subnet_id = var.subnet_resource.id
  }

  dynamic "ssl_certificate" {
    for_each = var.certificates
    iterator = self
    content {
      name                = lookup(self.value, "name")
      key_vault_secret_id = lookup(self.value, "key_vault_secret_id")
    }
  }

  frontend_port {
    name = local.frontend_port_name
    port = 443
  }

  dynamic "frontend_ip_configuration" {
    for_each = var.fe_configs
    iterator = self
    content {
      name                          = self.value == "public" ? local.frontend_ip_configuration_name : local.frontend_private_ip_configuration_name
      public_ip_address_id          = self.value == "public" ? azurerm_public_ip.this[0].id : null
      private_ip_address_allocation = self.value == "public" ? null : var.agw_tier == "WAFv2" ? "Static" : var.agw_private_ip_index == null ? "Dynamic" : "Static"
      subnet_id                     = self.value == "public" ? null : var.subnet_resource.id
      private_ip_address            = self.value == "public" || var.agw_private_ip_index == null ? null : cidrhost(var.subnet_resource.address_prefixes[0], var.agw_private_ip_index)
    }
  }

  dynamic "backend_address_pool" {
    for_each = local.backend_address_pool
    iterator = self
    content {
      name  = format("%s%s", self.key, var.backend_address_pool_suffix)
      fqdns = self.value
    }
  }

  dynamic "http_listener" {
    for_each = var.mappings
    iterator = self
    content {
      name                           = format("%s%s", split(".", self.key)[0], var.http_listener_suffix)
      frontend_ip_configuration_name = var.agw_listens_on == "public" ? local.frontend_ip_configuration_name : local.frontend_private_ip_configuration_name
      frontend_port_name             = local.frontend_port_name
      host_name                      = self.key
      protocol                       = "Https"
      ssl_certificate_name           = join("_", slice(split(".", self.key), 1, length(split(".", self.key))))
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.mappings
    iterator = self
    content {
      name                       = format("%s%s", split(".", self.key)[0], var.request_routing_rule_suffix)
      rule_type                  = "Basic"
      http_listener_name         = format("%s%s", split(".", self.key)[0], var.http_listener_suffix)
      backend_address_pool_name  = format("%s%s", self.value["pool_name"], var.backend_address_pool_suffix)
      backend_http_settings_name = format("%s%s", split(".", self.key)[0], var.backend_http_settings_suffix)
      priority                   = self.value["priority"]
    }
  }

  dynamic "probe" {
    for_each = local.mappings_with_probe
    iterator = self
    content {
      name                                      = format("%s%s", split(".", self.key)[0], var.probe_suffix)
      protocol                                  = lookup(self.value, "backend_protocol", "Https")
      path                                      = self.value["probe_path"]
      interval                                  = var.agw_probe_interval
      timeout                                   = var.agw_probe_timeout
      unhealthy_threshold                       = var.agw_probe_unhealthy_threshold
      minimum_servers                           = lookup(self.value, "minimum_servers", null)
      pick_host_name_from_backend_http_settings = true

      match {
        status_code = lookup(self.value, "probe_status_code", ["200-399"])
        body        = lookup(self.value, "probe_body_text", "")
      }
    }
  }

  dynamic "backend_http_settings" {
    for_each = var.mappings
    iterator = self
    content {
      name                                = format("%s%s", split(".", self.key)[0], var.backend_http_settings_suffix)
      cookie_based_affinity               = lookup(self.value, "cookie_based_affinity", var.cookie_based_affinity)
      affinity_cookie_name                = "ApplicationGatewayAffinity" # To prevent recreation on every terraform run. It looks similar to: https://github.com/hashicorp/terraform-provider-azurerm/issues/16695
      port                                = lookup(self.value, "backend_port", 443)
      protocol                            = lookup(self.value, "backend_protocol", "Https")
      request_timeout                     = lookup(self.value, "request_timeout", var.agw_http_request_timeout)
      host_name                           = contains(keys(self.value), "is_web_app") ? null : self.key
      pick_host_name_from_backend_address = contains(keys(self.value), "is_web_app") ? true : null
      probe_name                          = contains(keys(self.value), "probe_path") ? format("%s%s", split(".", self.key)[0], var.probe_suffix) : null
      path                                = lookup(self.value, "http_path", null)

      connection_draining {
        enabled           = length(lookup(local.backend_address_pool, self.value["pool_name"], [])) > 1
        drain_timeout_sec = var.connection_draining_timeout
      }
    }
  }

  identity {
    identity_ids = [azurerm_user_assigned_identity.this.id]
    type         = "UserAssigned"
  }

  tags = merge(
    var.tags,
    {
      "resource" = "application gateway"
    },
  )

  depends_on = [var.module_depends_on]
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  name                       = "SendAllToLogAnalytics"
  target_resource_id         = azurerm_application_gateway.agw.id
  log_analytics_workspace_id = var.log_analytics_id

  dynamic "log" {
    for_each = ["ApplicationGatewayAccessLog", "ApplicationGatewayPerformanceLog", "ApplicationGatewayFirewallLog"]
    content {
      category = log.value

      retention_policy {
        enabled = false
      }
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = false

    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "alienvault" {
  count = var.eventhub_policy.name != null ? 1 : 0

  name                           = "Stream_to_AlienVault"
  target_resource_id             = azurerm_application_gateway.agw.id
  eventhub_authorization_rule_id = var.eventhub_policy.id
  eventhub_name                  = var.eventhub_name

  dynamic "log" {
    for_each = {
      "ApplicationGatewayAccessLog"      = false,
      "ApplicationGatewayPerformanceLog" = false,
      "ApplicationGatewayFirewallLog"    = true,
    }

    content {
      category = log.key
      enabled  = log.value

      retention_policy {
        enabled = false
      }
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = false

    retention_policy {
      enabled = false
    }
  }
}
