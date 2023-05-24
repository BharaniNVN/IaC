resource "azurerm_resource_group" "fw_rg" {
  name     = "${local.deprecated_prefix2}-fw-rg"
  location = var.location

  tags = merge(
    local.tags,
    {
      "resource" = "resource group"
    },
  )
}

resource "azurerm_public_ip" "fw_pip_1" {
  name                = "${local.deprecated_prefix2}-fw-pip-1"
  location            = azurerm_resource_group.fw_rg.location
  resource_group_name = azurerm_resource_group.fw_rg.name
  allocation_method   = "Static"
  domain_name_label   = format("%s%s%s", local.deprecated_prefix2, var.public_ip_domain_suffix, "-fw")
  sku                 = "Standard"
  zones               = [1, 2, 3]

  tags = merge(
    local.tags,
    {
      "resource" = "public ip"
    },
  )
}

resource "azurerm_firewall" "nonprod_fw" {
  name                = "${local.deprecated_prefix2}-fw"
  location            = azurerm_resource_group.fw_rg.location
  resource_group_name = azurerm_resource_group.fw_rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  
  ip_configuration {
    name                 = "fwconfig-pip-1"
    subnet_id            = azurerm_subnet.nonprod_fw_subnet.id
    public_ip_address_id = azurerm_public_ip.fw_pip_1.id
  }

  tags = merge(
    local.tags,
    {
      "resource" = "azure firewall"
    },
  )
}

resource "azurerm_firewall_network_rule_collection" "fw_netw_rules_collection" {
  name                = "global-rules"
  azure_firewall_name = azurerm_firewall.nonprod_fw.name
  resource_group_name = azurerm_resource_group.fw_rg.name
  priority            = 1000
  action              = "Allow"

  rule {
    name                  = "Azure KMS for Windows activation"
    source_addresses      = azurerm_virtual_network.vnet.address_space
    destination_ports     = ["1688"]
    destination_addresses = ["*"]
    protocols             = ["TCP"]
  }

  rule {
    name                  = "DNS names resolution"
    source_addresses      = azurerm_virtual_network.vnet.address_space
    destination_ports     = ["53"]
    destination_addresses = ["*"]
    protocols             = ["UDP", "TCP"]
  }

  dynamic "rule" {
    for_each = local.dns_objects_fw

    content {
      name                  = format("Access to %s.%s", rule.value["name"], rule.value["zone"])
      source_addresses      = azurerm_virtual_network.vnet.address_space
      destination_ports     = rule.value["ports"]
      destination_addresses = rule.value["ip"]
      protocols             = rule.value["protocols"]
    }
  }
}

resource "azurerm_firewall_application_rule_collection" "this" {
  name                = "global-rules"
  azure_firewall_name = azurerm_firewall.nonprod_fw.name
  resource_group_name = azurerm_resource_group.fw_rg.name
  priority            = 1000
  action              = "Allow"

  rule {
    name             = "Internet http(s) access"
    source_addresses = concat(azurerm_virtual_network.vnet.address_space, local.pipelines_agent_subnet_resource.address_prefixes)
    target_fqdns     = ["*"]

    protocol {
      port = "80"
      type = "Http"
    }

    protocol {
      port = "8080"
      type = "Http"
    }

    protocol {
      port = "443"
      type = "Https"
    }
  }
}

resource "azurerm_firewall_network_rule_collection" "pipelines_agent" {
  name                = "pipelines-agent"
  azure_firewall_name = azurerm_firewall.nonprod_fw.name
  resource_group_name = azurerm_resource_group.fw_rg.name
  priority            = 1020
  action              = "Allow"

  rule {
    name                  = "outbound"
    source_addresses      = local.pipelines_agent_subnet_resource.address_prefixes
    destination_ports     = ["*"]
    destination_addresses = ["*"]
    protocols             = ["Any"]
  }
}

resource "azurerm_storage_account" "firewall_logs" {
  name                            = format("%sfwlogsstore", local.prefix)
  resource_group_name             = azurerm_resource_group.fw_rg.name
  location                        = azurerm_resource_group.fw_rg.location
  account_kind                    = "Storage"
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
  enable_https_traffic_only       = true
  min_tls_version                 = "TLS1_2"

  tags = merge(
    local.tags,
    {
      "resource" = "storage account"
    },
  )
}

resource "azurerm_monitor_diagnostic_setting" "firewall" {
  name                           = "SendLogs"
  target_resource_id             = azurerm_firewall.nonprod_fw.id
  storage_account_id             = azurerm_storage_account.firewall_logs.id
  log_analytics_destination_type = "AzureDiagnostics"
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.fw_la.id

  dynamic "log" {
    for_each = {
      "AzureFirewallDnsProxy"        = false,
      "AzureFirewallApplicationRule" = true,
      "AzureFirewallNetworkRule"     = true,
    }

    content {
      category = log.key
      enabled  = log.value

      retention_policy {
        enabled = log.value
        days    = log.value ? 365 : 0
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
