module "agw" {
  source = "../../../modules/terraform/app_gateway/"

  resource_group_name           = azurerm_resource_group.network.name
  resource_prefix               = local.deprecated_prefix
  subnet_resource               = azurerm_subnet.wafsubnet
  cookie_based_affinity         = "Disabled"
  agw_probe_match_statuscodes   = ["401"]
  connection_draining_timeout   = 300
  agw_probe_unhealthy_threshold = 3
  agw_probe_timeout             = 30
  agw_probe_interval            = 90
  agw_sku                       = "WAF_v2"
  agw_tier                      = "WAF_v2"
  agw_capacity                  = "2"
  waf_mode                      = "Detection"
  agw_private_ip_index          = 5
  log_analytics_id              = azurerm_log_analytics_workspace.this.id
  eventhub_policy               = azurerm_eventhub_namespace_authorization_rule.alienvault
  eventhub_name                 = azurerm_eventhub.alienvault.name

  fe_configs = [
    "public",
    "private",
  ]

  certificates = [
    {
      "name"                = "careanyware_com"
      "key_vault_id"        = data.azurerm_key_vault.initial.id
      "key_vault_secret_id" = trimsuffix(data.azurerm_key_vault_certificate.careanyware_com.secret_id, "/${data.azurerm_key_vault_certificate.careanyware_com.version}")
    },
    {
      "name"                = "matrixcarehhp_com"
      "key_vault_id"        = data.azurerm_key_vault.initial.id
      "key_vault_secret_id" = trimsuffix(data.azurerm_key_vault_secret.matrixcarehhp_com.id, "/${data.azurerm_key_vault_secret.matrixcarehhp_com.version}")
    },
    {
      "name"                = "healthcarefirst_com"
      "key_vault_id"        = data.azurerm_key_vault.initial.id
      "key_vault_secret_id" = trimsuffix(data.azurerm_key_vault_certificate.healthcarefirst_com.secret_id, "/${data.azurerm_key_vault_certificate.healthcarefirst_com.version}")
    },
  ]

  mappings = {
    format("%s.%s", local.app01, local.aad_domain_name) = { "pool_name" = local.app01, "servers" = format("%s-as.azurewebsites.net", local.app01), "probe_path" = "/", "is_web_app" = "", "http_path" = "/", "probe_status_code" = ["200-399", "403"], "request_timeout" = 60, priority = 10 },
    format("%s.%s", local.app02, local.aad_domain_name) = { "pool_name" = local.app02, "servers" = format("%s.azurewebsites.net", local.app02), "probe_path" = "/", "is_web_app" = "", "http_path" = "/", priority = 20 },
    "rcm.healthcarefirst.com"                           = { "pool_name" = local.app03, "servers" = format("%s-as.azurewebsites.net", local.app03), "probe_path" = "/", "is_web_app" = "", "http_path" = "/", "probe_status_code" = ["200-399"], priority = 30 },
    format("%s.%s", local.app04, local.aad_domain_name) = { "pool_name" = local.app04, "servers" = "prodana-as.azurewebsites.net", "probe_path" = "/", "http_path" = "/", "request_timeout" = 60, priority = 40 },
    #region P7 AFO
    format("secure71.%s", var.external_domain_name) = { "pool_name" = "prodafo-afo71", "servers" = ["10.105.2.35"], "probe_path" = "/hhweb/images/accept.png", "request_timeout" = 600, priority = 50 },
    format("secure72.%s", var.external_domain_name) = { "pool_name" = "prodafo-afo72", "servers" = ["10.105.2.36"], "probe_path" = "/hhweb/images/accept.png", "request_timeout" = 600, priority = 60 },
    #endregion P7 AFO
  }

  tags = merge(
    local.tags,
    {
      "application" = "shared"
    },
  )
}

resource "azurerm_firewall_nat_rule_collection" "agw" {
  name                = format("%s-agw", lower(local.deprecated_prefix))
  azure_firewall_name = data.terraform_remote_state.shared.outputs.fw.name
  resource_group_name = data.terraform_remote_state.shared.outputs.fw.resource_group_name
  priority            = 600
  action              = "Dnat"

  rule {
    name                  = "afo-https"
    source_addresses      = ["*"]
    destination_ports     = ["443"]
    translated_port       = "443"
    translated_address    = module.agw.private_ip
    destination_addresses = [data.terraform_remote_state.shared.outputs.azure_firewall_public_ip_resource_prod_1.ip_address]
    protocols             = ["TCP"]
  }

  rule {
    name                  = "oasis-https"
    source_addresses      = ["*"]
    destination_ports     = ["443"]
    translated_port       = "443"
    translated_address    = module.agw.private_ip
    destination_addresses = [data.terraform_remote_state.shared.outputs.azure_firewall_public_ip_resource_prod_2.ip_address]
    protocols             = ["TCP"]
  }

  rule {
    name                  = "codingcenter-https"
    source_addresses      = ["*"]
    destination_ports     = ["443"]
    translated_port       = "443"
    translated_address    = module.agw.private_ip
    destination_addresses = [data.terraform_remote_state.shared.outputs.azure_firewall_public_ip_resource_prod_3.ip_address]
    protocols             = ["TCP"]
  }

  rule {
    name                  = "myanalytics-https"
    source_addresses      = ["*"]
    destination_ports     = ["443"]
    translated_port       = "443"
    translated_address    = module.agw.private_ip
    destination_addresses = [data.terraform_remote_state.shared.outputs.azure_firewall_public_ip_resource_prod_4.ip_address]
    protocols             = ["TCP"]
  }
}
