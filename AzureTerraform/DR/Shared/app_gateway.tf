resource "azurerm_resource_group" "agw" {
  name     = "${local.deprecated_prefix}-agw-rg"
  location = var.location

  tags = merge(
    local.tags,
    {
      "resource" = "resource group"
    },
  )
}

module "agw" {
  source = "../../../modules/terraform/app_gateway/"

  resource_group_name           = azurerm_resource_group.agw.name
  resource_prefix               = local.deprecated_prefix
  subnet_resource               = azurerm_subnet.agw_waf_subnet
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
  eventhub_policy               = data.terraform_remote_state.prod_shared.outputs.eventhub_policy
  eventhub_name                 = data.terraform_remote_state.prod_shared.outputs.eventhub_name

  fe_configs = [
    "public",
    "private",
  ]

  certificates = [
    {
      "name"                = "careanyware_com"
      "key_vault_id"        = data.azurerm_key_vault.initial.id
      "key_vault_secret_id" = trimsuffix(data.azurerm_key_vault_certificate.careanyware_com.secret_id, "/${data.azurerm_key_vault_certificate.careanyware_com.version}")
    }
  ]

  mappings = {
    "authapi.careanyware.com"        = { pool_name = "lau", servers = ["10.105.33.101", "10.105.33.102"], probe_path = "/", minimum_servers = 1, priority = 10 },
    "configextapi.careanyware.com"   = { pool_name = "hhpwf", servers = ["10.105.33.81", "10.105.33.82"], probe_path = "/api/ping", minimum_servers = 1, priority = 20 },
    "extapi.careanyware.com"         = { pool_name = "hhpwf", probe_path = "/ping", minimum_servers = 1, request_timeout = 30, priority = 30 },
    "gc.careanyware.com"             = { pool_name = "hhpwf", probe_path = "/", minimum_servers = 1, priority = 40 },
    "integextapi.careanyware.com"    = { pool_name = "hhpwf", probe_path = "/api/ping", probe_status_code = ["401"], probe_body_text = "The Brightree Partner Token is missing", minimum_servers = 1, request_timeout = 30, priority = 50 },
    "integextwcf.careanyware.com"    = { pool_name = "hhpwf", probe_path = "/services/pingtest.svc", minimum_servers = 1, priority = 60 },
    "login.careanyware.com"          = { pool_name = "lau", probe_path = "/", minimum_servers = 1, priority = 70 },
    "missioncontrol.careanyware.com" = { pool_name = "hhpwf", probe_path = "/images/imgBanner.gif", minimum_servers = 1, priority = 80 },
    "mobileapi.brightree.net"        = { pool_name = "cawws01", servers = ["10.105.33.73"], probe_path = "/VersionGatewayService/api/ping", request_timeout = 300, priority = 90 },
    "mobileapi2.brightree.net"       = { pool_name = "sync01", servers = ["10.105.33.70"], probe_path = "/VersionGatewayService/api/ping", request_timeout = 300, priority = 100 },
    "mobileapi4.brightree.net"       = { pool_name = "sync02", servers = ["10.105.33.71"], probe_path = "/VersionGatewayService/api/ping", request_timeout = 300, priority = 110 },
    "mobileapi7.careanyware.com"     = { pool_name = "sync03", servers = ["10.105.33.72"], probe_path = "/VersionGatewayService/api/ping", request_timeout = 300, priority = 120 },
    "secure21.careanyware.com"       = { pool_name = "afo21", servers = ["10.105.33.15"], probe_path = "/hhweb/images/accept.png", request_timeout = 600, priority = 130 },
    "secure22.careanyware.com"       = { pool_name = "afo22", servers = ["10.105.33.16"], probe_path = "/hhweb/images/accept.png", request_timeout = 600, priority = 140 },
    "secure41.careanyware.com"       = { pool_name = "afo41", servers = ["10.105.33.20"], probe_path = "/hhweb/images/accept.png", request_timeout = 600, priority = 150 },
    "secure42.careanyware.com"       = { pool_name = "afo42", servers = ["10.105.33.21"], probe_path = "/hhweb/images/accept.png", request_timeout = 600, priority = 160 },
    "secure51.careanyware.com"       = { pool_name = "afo51", servers = ["10.105.33.25"], probe_path = "/hhweb/images/accept.png", request_timeout = 600, priority = 170 },
    "secure52.careanyware.com"       = { pool_name = "afo52", servers = ["10.105.33.26"], probe_path = "/hhweb/images/accept.png", request_timeout = 600, priority = 180 },
    "secure61.careanyware.com"       = { pool_name = "afo61", servers = ["10.105.33.30"], probe_path = "/hhweb/images/accept.png", request_timeout = 600, priority = 190 },
    "secure62.careanyware.com"       = { pool_name = "afo62", servers = ["10.105.33.31"], probe_path = "/hhweb/images/accept.png", request_timeout = 600, priority = 200 },
    "secure71.careanyware.com"       = { pool_name = "afo71", servers = ["10.105.33.35"], probe_path = "/hhweb/images/accept.png", request_timeout = 600, priority = 210 },
    "secure72.careanyware.com"       = { pool_name = "afo72", servers = ["10.105.33.36"], probe_path = "/hhweb/images/accept.png", request_timeout = 600, priority = 220 },
    "secure81.careanyware.com"       = { pool_name = "afo81", servers = ["10.105.33.40"], probe_path = "/hhweb/images/accept.png", request_timeout = 600, priority = 230 },
    "secure82.careanyware.com"       = { pool_name = "afo82", servers = ["10.105.33.41"], probe_path = "/hhweb/images/accept.png", request_timeout = 600, priority = 240 },
  }

  tags = local.tags
}
