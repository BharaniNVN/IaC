module "agw" {
  source = "../../../modules/terraform/app_gateway/"

  resource_group_name           = azurerm_resource_group.deprecated_rg.name
  resource_prefix               = local.deprecated_prefix2
  subnet_resource               = azurerm_subnet.wafsubnet
  cookie_based_affinity         = "Disabled"
  agw_probe_match_statuscodes   = ["401"]
  connection_draining_timeout   = 300
  agw_probe_unhealthy_threshold = 3
  agw_probe_timeout             = 30
  agw_probe_interval            = 90
  agw_sku                       = "WAF_v2"
  agw_tier                      = "WAF_v2"
  agw_capacity                  = "1"
  waf_mode                      = "Detection"
  agw_private_ip_index          = 5
  log_analytics_id              = azurerm_log_analytics_workspace.nonprod.id
  eventhub_policy               = azurerm_eventhub_namespace_authorization_rule.alienvault
  eventhub_name                 = azurerm_eventhub.alienvault.name

  fe_configs = [
    "public",
    "private",
  ]

  certificates = [
    {
      "name"                = "mxhhpdev_com"
      "key_vault_id"        = data.azurerm_key_vault.initial.id
      "key_vault_secret_id" = trimsuffix(data.azurerm_key_vault_secret.mxhhpdev_com.id, "/${data.azurerm_key_vault_secret.mxhhpdev_com.version}")
    },
  ]

  mappings = {
    format("%s.%s", local.app01, var.external_domain_name) = { "pool_name" = local.app01, "servers" = format("%s.azurewebsites.net", local.app01), "probe_path" = "/", "is_web_app" = "", "http_path" = "/", "probe_status_code" = ["200-399", "403"], priority = 10 },
    format("%s.%s", local.app02, var.external_domain_name) = { "pool_name" = local.app02, "servers" = format("%s.azurewebsites.net", local.app02), "probe_path" = "/", "is_web_app" = "", "http_path" = "/", priority = 20 },
    format("%s.%s", local.app03, var.external_domain_name) = { "pool_name" = local.app03, "servers" = format("%s.azurewebsites.net", local.app03), "probe_path" = "/", "is_web_app" = "", "http_path" = "/", "probe_status_code" = ["200-399", "403"], priority = 30 },
    format("%s.%s", local.app04, var.external_domain_name) = { "pool_name" = local.app04, "servers" = format("%s.azurewebsites.net", local.app04), "probe_path" = "/", "is_web_app" = "", "http_path" = "/", priority = 40 },
    format("%s.%s", local.app05, var.external_domain_name) = { "pool_name" = local.app05, "servers" = format("%s.azurewebsites.net", local.app05), "probe_path" = "/", "is_web_app" = "", "http_path" = "/", "probe_status_code" = ["200-399", "403"], priority = 50 },
    format("%s.%s", local.app06, var.external_domain_name) = { "pool_name" = local.app06, "servers" = format("%s.azurewebsites.net", local.app06), "probe_path" = "/", "is_web_app" = "", "http_path" = "/", priority = 60 },
    format("%s.%s", local.app07, var.external_domain_name) = { "pool_name" = local.app07, "servers" = format("%s.azurewebsites.net", local.app07), "probe_path" = "/", "is_web_app" = "", "http_path" = "/", "probe_status_code" = ["200-399", "403"], priority = 70 },
    format("%s.%s", local.app08, var.external_domain_name) = { "pool_name" = local.app08, "servers" = format("%s.azurewebsites.net", local.app08), "probe_path" = "/", "is_web_app" = "", "http_path" = "/", priority = 80 },
    format("%s.%s", local.app09, var.external_domain_name) = { "pool_name" = local.app09, "servers" = format("%s.azurewebsites.net", local.app09), "probe_path" = "/", "is_web_app" = "", "http_path" = "/", "probe_status_code" = ["200-399"], priority = 90 },
    format("%s.%s", local.app10, var.external_domain_name) = { "pool_name" = local.app10, "servers" = format("%s.azurewebsites.net", local.app10), "probe_path" = "/", "is_web_app" = "", "http_path" = "/", "probe_status_code" = ["200-399"], priority = 100 },
    format("%s.%s", local.app11, var.external_domain_name) = { "pool_name" = local.app11, "servers" = format("%s.azurewebsites.net", local.app11), "probe_path" = "/", "http_path" = "/", "request_timeout" = 60, priority = 110 },
    format("%s.%s", local.app12, var.external_domain_name) = { "pool_name" = local.app12, "servers" = format("%s.azurewebsites.net", local.app12), "probe_path" = "/", "http_path" = "/", "request_timeout" = 60, priority = 120 },
    format("%s.%s", local.app13, var.external_domain_name) = { "pool_name" = local.app13, "servers" = format("%s.azurewebsites.net", local.app13), "probe_path" = "/", "http_path" = "/", "request_timeout" = 60, priority = 130 },
    format("%s.%s", local.app14, var.external_domain_name) = { "pool_name" = local.app14, "servers" = format("%s.azurewebsites.net", local.app14), "probe_path" = "/", "http_path" = "/", "request_timeout" = 60, priority = 140 },
    format("%s.%s", local.app15, var.external_domain_name) = { "pool_name" = local.app15, "servers" = format("%s.azurewebsites.net", local.app15), "probe_path" = "/", "is_web_app" = "", "http_path" = "/", priority = 150 },
    format("%s.%s", local.app16, var.external_domain_name) = { "pool_name" = local.app16, "servers" = format("%s.azurewebsites.net", local.app16), "probe_path" = "/dashboards/test/1", "is_web_app" = "", "http_path" = "/", priority = 160 },
    #region DEV AFO
    format("devafo-authapi.%s", var.external_domain_name)        = { "pool_name" = "devafo-lauaz", "servers" = ["10.105.130.58", "10.105.130.59"], "probe_path" = "/", "minimum_servers" = 1, priority = 170 },
    format("devafo-configextapi.%s", var.external_domain_name)   = { "pool_name" = "devafo-wfaz", "servers" = ["10.105.130.43", "10.105.130.44"], "probe_path" = "/api/ping", "minimum_servers" = 1, priority = 180 },
    format("devafo-extapi.%s", var.external_domain_name)         = { "pool_name" = "devafo-wfaz", "probe_path" = "/ping", "minimum_servers" = 1, "request_timeout" = 30, priority = 190 },
    format("devafo-gc.%s", var.external_domain_name)             = { "pool_name" = "devafo-wfaz", "probe_path" = "/", "minimum_servers" = 1, priority = 200 },
    format("devafo-integextapi.%s", var.external_domain_name)    = { "pool_name" = "devafo-wfaz", "probe_path" = "/api/ping", "probe_status_code" = ["401"], "probe_body_text" = "The Brightree Partner Token is missing", "minimum_servers" = 1, "request_timeout" = 30, priority = 210 },
    format("devafo-integextwcf.%s", var.external_domain_name)    = { "pool_name" = "devafo-wfaz", "probe_path" = "/services/pingtest.svc", "minimum_servers" = 1, priority = 220 },
    format("devafo-login.%s", var.external_domain_name)          = { "pool_name" = "devafo-lauaz", "probe_path" = "/", "minimum_servers" = 1, priority = 230 },
    format("devafo-missioncontrol.%s", var.external_domain_name) = { "pool_name" = "devafo-wfaz", "probe_path" = "/images/imgBanner.gif", "minimum_servers" = 1, "request_timeout" = 30, priority = 240 },
    format("devafo-mobileapi.%s", var.external_domain_name)      = { "pool_name" = "devafo-syncaz", "servers" = ["10.105.130.47", "10.105.130.48"], "probe_path" = "/VersionGatewayService/api/ping", "request_timeout" = 300, priority = 250 },
    format("devafo-secure1.%s", var.external_domain_name)        = { "pool_name" = "devafo-afoaz01", "servers" = ["10.105.130.38"], "probe_path" = "/hhweb/images/accept.png", "request_timeout" = 600, priority = 260 },
    format("devafo-secure2.%s", var.external_domain_name)        = { "pool_name" = "devafo-afoaz02", "servers" = ["10.105.130.39"], "probe_path" = "/hhweb/images/accept.png", "request_timeout" = 600, priority = 270 },
    format("devafo-blue-secure.%s", var.external_domain_name)    = { "pool_name" = "devafo-canary", "servers" = ["10.105.130.40", "10.105.130.41"], "probe_path" = "/hhweb/images/accept.png", "request_timeout" = 600, "cookie_based_affinity" = "Enabled", priority = 280 },
    format("devafo-green-secure.%s", var.external_domain_name)   = { "pool_name" = "devafo-canary", "servers" = ["10.105.130.40", "10.105.130.41"], "probe_path" = "/hhweb/images/accept.png", "request_timeout" = 600, "cookie_based_affinity" = "Enabled", priority = 290 },
    format("devafo-red-secure.%s", var.external_domain_name)     = { "pool_name" = "devafo-canary", "servers" = ["10.105.130.40", "10.105.130.41"], "probe_path" = "/hhweb/images/accept.png", "request_timeout" = 600, "cookie_based_affinity" = "Enabled", priority = 300 },
    format("devafo-gold-secure.%s", var.external_domain_name)    = { "pool_name" = "devafo-canary", "servers" = ["10.105.130.40", "10.105.130.41"], "probe_path" = "/hhweb/images/accept.png", "request_timeout" = 600, "cookie_based_affinity" = "Enabled", priority = 310 },
    format("devafo-silver-secure.%s", var.external_domain_name)  = { "pool_name" = "devafo-canary", "servers" = ["10.105.130.40", "10.105.130.41"], "probe_path" = "/hhweb/images/accept.png", "request_timeout" = 600, "cookie_based_affinity" = "Enabled", priority = 320 },
    format("devafo-black-secure.%s", var.external_domain_name)   = { "pool_name" = "devafo-canary", "servers" = ["10.105.130.40", "10.105.130.41"], "probe_path" = "/hhweb/images/accept.png", "request_timeout" = 600, "cookie_based_affinity" = "Enabled", priority = 330 },
    format("devafo-purple-secure.%s", var.external_domain_name)  = { "pool_name" = "devafo-canary", "servers" = ["10.105.130.40", "10.105.130.41"], "probe_path" = "/hhweb/images/accept.png", "request_timeout" = 600, "cookie_based_affinity" = "Enabled", priority = 340 },
    format("devafo-orange-secure.%s", var.external_domain_name)  = { "pool_name" = "devafo-canary", "servers" = ["10.105.130.40", "10.105.130.41"], "probe_path" = "/hhweb/images/accept.png", "request_timeout" = 600, "cookie_based_affinity" = "Enabled", priority = 350 },
    format("devafo-magenta-secure.%s", var.external_domain_name) = { "pool_name" = "devafo-canary", "servers" = ["10.105.130.40", "10.105.130.41"], "probe_path" = "/hhweb/images/accept.png", "request_timeout" = 600, "cookie_based_affinity" = "Enabled", priority = 360 },
    format("devafo-violet-secure.%s", var.external_domain_name)  = { "pool_name" = "devafo-canary", "servers" = ["10.105.130.40", "10.105.130.41"], "probe_path" = "/hhweb/images/accept.png", "request_timeout" = 600, "cookie_based_affinity" = "Enabled", priority = 370 },
    #endregion Dev AFO
    #region Stage AFO
    format("stgafo-authapi.%s", var.external_domain_name)        = { "pool_name" = "stgafo-lauaz", "servers" = ["10.105.130.186", "10.105.130.187"], "probe_path" = "/", "minimum_servers" = 1, priority = 380 },
    format("stgafo-configextapi.%s", var.external_domain_name)   = { "pool_name" = "stgafo-wfaz", "servers" = ["10.105.130.171", "10.105.130.172"], "probe_path" = "/api/ping", "minimum_servers" = 1, priority = 390 },
    format("stgafo-extapi.%s", var.external_domain_name)         = { "pool_name" = "stgafo-wfaz", "probe_path" = "/ping", "minimum_servers" = 1, "request_timeout" = 30, priority = 400 },
    format("stgafo-gc.%s", var.external_domain_name)             = { "pool_name" = "stgafo-wfaz", "probe_path" = "/", "minimum_servers" = 1, priority = 410 },
    format("stgafo-integextapi.%s", var.external_domain_name)    = { "pool_name" = "stgafo-wfaz", "probe_path" = "/api/ping", "probe_status_code" = ["401"], "probe_body_text" = "The Brightree Partner Token is missing", "minimum_servers" = 1, "request_timeout" = 30, priority = 420 },
    format("stgafo-integextwcf.%s", var.external_domain_name)    = { "pool_name" = "stgafo-wfaz", "probe_path" = "/services/pingtest.svc", "minimum_servers" = 1, priority = 430 },
    format("stgafo-login.%s", var.external_domain_name)          = { "pool_name" = "stgafo-lauaz", "probe_path" = "/", "minimum_servers" = 1, priority = 440 },
    format("stgafo-missioncontrol.%s", var.external_domain_name) = { "pool_name" = "stgafo-wfaz", "probe_path" = "/images/imgBanner.gif", "minimum_servers" = 1, "request_timeout" = 30, priority = 450 },
    format("stgafo-mobileapi.%s", var.external_domain_name)      = { "pool_name" = "stgafo-syncaz", "servers" = ["10.105.130.175", "10.105.130.176"], "probe_path" = "/VersionGatewayService/api/ping", "request_timeout" = 300, priority = 460 },
    format("stgafo-secure1.%s", var.external_domain_name)        = { "pool_name" = "stgafo-afoaz01", "servers" = ["10.105.130.166"], "probe_path" = "/hhweb/images/accept.png", "request_timeout" = 600, priority = 470 },
    format("stgafo-secure2.%s", var.external_domain_name)        = { "pool_name" = "stgafo-afoaz02", "servers" = ["10.105.130.167"], "probe_path" = "/hhweb/images/accept.png", "request_timeout" = 600, priority = 480 },
    #endregion Stage AFO
    #region Hotfix AFO
    format("hfxafo-authapi.%s", var.external_domain_name)        = { "pool_name" = "hfxafo-lauaz", "servers" = ["10.105.130.122", "10.105.130.123"], "probe_path" = "/", "minimum_servers" = 1, priority = 490 },
    format("hfxafo-configextapi.%s", var.external_domain_name)   = { "pool_name" = "hfxafo-wfaz", "servers" = ["10.105.130.107", "10.105.130.108"], "probe_path" = "/api/ping", "minimum_servers" = 1, priority = 500 },
    format("hfxafo-extapi.%s", var.external_domain_name)         = { "pool_name" = "hfxafo-wfaz", "probe_path" = "/ping", "minimum_servers" = 1, "request_timeout" = 30, priority = 510 },
    format("hfxafo-gc.%s", var.external_domain_name)             = { "pool_name" = "hfxafo-wfaz", "probe_path" = "/", "minimum_servers" = 1, priority = 520 },
    format("hfxafo-integextapi.%s", var.external_domain_name)    = { "pool_name" = "hfxafo-wfaz", "probe_path" = "/api/ping", "probe_status_code" = ["401"], "probe_body_text" = "The Brightree Partner Token is missing", "minimum_servers" = 1, "request_timeout" = 30, priority = 530 },
    format("hfxafo-integextwcf.%s", var.external_domain_name)    = { "pool_name" = "hfxafo-wfaz", "probe_path" = "/services/pingtest.svc", "minimum_servers" = 1, priority = 540 },
    format("hfxafo-login.%s", var.external_domain_name)          = { "pool_name" = "hfxafo-lauaz", "probe_path" = "/", "minimum_servers" = 1, priority = 550 },
    format("hfxafo-missioncontrol.%s", var.external_domain_name) = { "pool_name" = "hfxafo-wfaz", "probe_path" = "/images/imgBanner.gif", "minimum_servers" = 1, "request_timeout" = 30, priority = 560 },
    format("hfxafo-mobileapi.%s", var.external_domain_name)      = { "pool_name" = "hfxafo-syncaz", "servers" = ["10.105.130.111", "10.105.130.112"], "probe_path" = "/VersionGatewayService/api/ping", "request_timeout" = 300, priority = 570 },
    format("hfxafo-secure1.%s", var.external_domain_name)        = { "pool_name" = "hfxafo-afoaz01", "servers" = ["10.105.130.102"], "probe_path" = "/hhweb/images/accept.png", "request_timeout" = 600, priority = 580 },
    format("hfxafo-secure2.%s", var.external_domain_name)        = { "pool_name" = "hfxafo-afoaz02", "servers" = ["10.105.130.103"], "probe_path" = "/hhweb/images/accept.png", "request_timeout" = 600, priority = 590 },
    #endregion Hotfix AFO
    #region QA Private Duty
    format("qapd-api.%s", var.external_domain_name)               = { "pool_name" = "qapd-webaz", "servers" = ["10.105.139.17", "10.105.139.18"], "probe_path" = "/2.77.0.0/api/QA/iris/pingNoAuth", "minimum_servers" = 1, "request_timeout" = 30, priority = 600 },
    format("qapd-app.%s", var.external_domain_name)               = { "pool_name" = "qapd-webaz", "probe_path" = "/web", "probe_status_code" = ["200-399"], "minimum_servers" = 1, "request_timeout" = 30, priority = 610 },
    format("qapd-auth.%s", var.external_domain_name)              = { "pool_name" = "qapd-webaz", "probe_path" = "/1.0/core/.well-known/openid-configuration", "minimum_servers" = 1, "request_timeout" = 30, priority = 620 },
    format("qapd-clickonce.%s", var.external_domain_name)         = { "pool_name" = "qapd-webaz", "probe_path" = "/robots.txt", "minimum_servers" = 1, "request_timeout" = 180, priority = 630 }, # higher timeout needed for WCF
    format("qapd-idm-api.%s", var.external_domain_name)              = { "pool_name" = "qapd-webaz", "servers" = ["10.105.139.17", "10.105.139.18"], "probe_path" = "/robots.txt", "minimum_servers" = 1, "request_timeout" = 30, priority = 640 },
    format("qapd-management.%s", var.external_domain_name)           = { "pool_name" = "qapd-webaz", "probe_path" = "/robots.txt", "minimum_servers" = 1, "request_timeout" = 30, priority = 650 },
    format("qapd-mgmtinterface.%s", var.external_domain_name)        = { "pool_name" = "qapd-webaz", "probe_path" = "/robots.txt", "minimum_servers" = 1, "request_timeout" = 180, priority = 660 }, # higher timeout needed for WCF
    format("qapd-reports.%s", var.external_domain_name)              = { "pool_name" = "qapd-ssrsaz01", "servers" = ["10.105.139.12"], "probe_path" = "/Reports", "minimum_servers" = 1, "request_timeout" = 180, priority = 670 },
    format("qapd-telephony-api.%s", var.external_domain_name)        = { "pool_name" = "qapd-webaz", "probe_path" = "/robots.txt", "minimum_servers" = 1, "request_timeout" = 30, priority = 680 },
    format("qapd-telephony-service.%s", var.external_domain_name)    = { "pool_name" = "qapd-webaz", "probe_path" = "/robots.txt", "minimum_servers" = 1, "request_timeout" = 180, priority = 690 }, # higher timeout needed for WCF
    format("qapd-clickonce-historic.%s", var.external_domain_name)   = { "pool_name" = "qapd-webaz", "probe_path" = "/robots.txt", "minimum_servers" = 1, "request_timeout" = 180, priority = 700 }, # higher timeout needed for WCF
    format("qapd-clickonce-regression.%s", var.external_domain_name) = { "pool_name" = "qapd-webaz", "probe_path" = "/robots.txt", "minimum_servers" = 1, "request_timeout" = 180, priority = 710 }, # higher timeout needed for WCF
    format("qapd-clickonce-release.%s", var.external_domain_name)    = { "pool_name" = "qapd-webaz", "probe_path" = "/robots.txt", "minimum_servers" = 1, "request_timeout" = 180, priority = 720 }, # higher timeout needed for WCF
    #endregion QA Private Duty
    format("enablement.%s", var.external_domain_name) = { "pool_name" = "enablement-grafana", "servers" = ["nonprodpbm-grafana-vm.internal.cloudapp.net"], "backend_port" = 3000, "backend_protocol" = "Http", "probe_path" = "/api/health", priority = 730 }
    #region DEV Content Builder
    format("devcb-app.%s", var.external_domain_name) = { "pool_name" = "devcb-app", "servers" = ["10.105.60.36"], "probe_path" = "/", "minimum_servers" = 1, "backend_port" = 80, "backend_protocol" = "Http", "request_timeout" = 30, priority = 740},
    #endrgion DEV Content Builder
  }
  
  tags = merge(
    local.tags,
    {
      "application" = "shared"
    },
  )
}
