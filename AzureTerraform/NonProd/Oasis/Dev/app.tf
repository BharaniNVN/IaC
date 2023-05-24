resource "azurerm_windows_web_app" "this" {
  name                    = "${local.deprecated_prefix}-as"
  location                = azurerm_resource_group.this.location
  resource_group_name     = azurerm_resource_group.this.name
  service_plan_id         = data.terraform_remote_state.oasis_shared.outputs.app_service_plan_id
  https_only              = true
  client_affinity_enabled = true

  app_settings = merge(
    data.external.app_service_appsettings.result,
    {
      "WEBSITE_NODE_DEFAULT_VERSION"   = var.website_node_def_ver
      "MSDEPLOY_RENAME_LOCKED_FILES"   = 1
      "APPINSIGHTS_INSTRUMENTATIONKEY" = module.application_insights.instrumentation_key
    }
  )

  site_config {
    always_on                = "true"
    default_documents        = ["index.html", "Default.html"]
    ftps_state               = "Disabled"
    http2_enabled            = "true"
    remote_debugging_enabled = "false"
    remote_debugging_version = var.remote_debugging_version
    use_32_bit_worker        = true

    application_stack {
      current_stack  = "dotnet"
      dotnet_version = var.dotnet_framework_version
    }

    ip_restriction {
      virtual_network_subnet_id = data.terraform_remote_state.nonprod_shared.outputs.agw_subnet_id
    }

    virtual_application {
      physical_path = "site\\api"
      preload       = false
      virtual_path  = "/api"
    }

    virtual_application {
      physical_path = "site\\wwwroot"
      preload       = true
      virtual_path  = "/"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = merge(
    local.tags,
    {
      "resource" = "windows web app"
    },
  )
}

resource "azurerm_monitor_diagnostic_setting" "app_service" {
  name                       = "SendAllToLogAnalytics"
  target_resource_id         = azurerm_windows_web_app.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  dynamic "log" {
    for_each = {
      "AppServiceIPSecAuditLogs" = false,
      "AppServicePlatformLogs"   = false,
      "AppServiceAppLogs"        = true,
      "AppServiceAuditLogs"      = true,
      "AppServiceConsoleLogs"    = true,
      "AppServiceHTTPLogs"       = true,
    }

    content {
      category = log.key
      enabled  = log.value

      retention_policy {
        enabled = false
        days    = 0
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

resource "azurerm_app_service_virtual_network_swift_connection" "app_service" {
  app_service_id = azurerm_windows_web_app.this.id
  subnet_id      = data.terraform_remote_state.oasis_shared.outputs.app_service_subnet.id
}

resource "random_uuid" "web" {}

resource "azuread_application" "web" {
  display_name     = local.application_name_web
  identifier_uris  = [format("https://%s/%s", data.terraform_remote_state.nonprod_shared.outputs.aad_domain_name, local.application_name_web)]
  owners           = [data.azurerm_client_config.current.object_id]
  sign_in_audience = "AzureADMultipleOrgs"

  api {
    oauth2_permission_scope {
      admin_consent_description  = format("Allow the application to access %s on behalf of the signed-in user.", local.application_name_web)
      admin_consent_display_name = format("Access %s", local.application_name_web)
      enabled                    = true
      id                         = random_uuid.web.result
      type                       = "User"
      user_consent_description   = format("Allow the application to access %s on your behalf.", local.application_name_web)
      user_consent_display_name  = format("Access %s", local.application_name_web)
      value                      = "user_impersonation"
    }
  }

  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph

    resource_access {
      id   = data.azuread_service_principal.microsoft_graph.oauth2_permission_scope_ids["User.Read"]
      type = "Scope"
    }
  }

  web {
    homepage_url  = local.homepage
    redirect_uris = [format("%s/auth-callback", local.homepage)]

    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }

  tags = ["terraform"]
}

resource "azuread_service_principal" "web" {
  application_id = azuread_application.web.application_id
  owners         = [data.azurerm_client_config.current.object_id]

  tags = ["terraform"]
}

resource "random_uuid" "api" {}

resource "azuread_application" "api" {
  display_name     = local.application_name_api
  identifier_uris  = [format("https://%s/%s", data.terraform_remote_state.nonprod_shared.outputs.aad_domain_name, local.application_name_api)]
  owners           = [data.azurerm_client_config.current.object_id]
  sign_in_audience = "AzureADMultipleOrgs"

  api {
    oauth2_permission_scope {
      admin_consent_description  = format("Allow the application to access %s on behalf of the signed-in user.", local.application_name_api)
      admin_consent_display_name = format("Access %s", local.application_name_api)
      enabled                    = true
      id                         = random_uuid.api.result
      type                       = "User"
      user_consent_description   = format("Allow the application to access %s on your behalf.", local.application_name_api)
      user_consent_display_name  = format("Access %s", local.application_name_api)
      value                      = "user_impersonation"
    }
  }

  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result.AzureActiveDirectoryGraph

    resource_access {
      id   = data.azuread_service_principal.azure_active_directory_graph.oauth2_permission_scope_ids["User.Read"]
      type = "Scope"
    }
  }

  web {
    homepage_url  = local.homepage
    redirect_uris = [format("%s/", local.homepage)]

    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }

  tags = ["terraform"]
}

resource "azuread_service_principal" "api" {
  application_id = azuread_application.api.application_id
  owners         = [data.azurerm_client_config.current.object_id]

  tags = ["terraform"]
}
