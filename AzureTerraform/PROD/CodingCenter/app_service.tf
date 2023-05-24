resource "azurerm_app_service" "this" {
  name                = "${lower(var.deprecated_application_prefix)}-as"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  app_service_plan_id = azurerm_app_service_plan.this.id
  https_only          = "true"

  site_config {
    dotnet_framework_version  = var.dotnet_framework_version
    always_on                 = "true"
    http2_enabled             = "true"
    remote_debugging_enabled  = "false"
    remote_debugging_version  = var.remote_debugging_version
    default_documents         = ["index.html", "Default.html"]
    use_32_bit_worker_process = "false"
    websockets_enabled        = "true"

    ip_restriction {
      virtual_network_subnet_id = data.terraform_remote_state.prod_shared.outputs.agw_subnet_id
    }
  }

  app_settings = merge(
    data.external.app_service_appsettings.result,
    {
      "MSDEPLOY_RENAME_LOCKED_FILES"                    = 1
      "APPINSIGHTS_INSTRUMENTATIONKEY"                  = module.application_insights.instrumentation_key
      "AppSettings__ConnectionString"                   = local.connection_string
      "AppSettings__SendGridAPIKey"                     = module.sendgrid_apikey.sendgrid_api_key_value
      "AppSettings__SendGridAPIKeyUserName"             = module.sendgrid_apikey.sendgrid_api_key_username
      "APPINSIGHTS_PROFILERFEATURE_VERSION"             = "disabled"
      "APPINSIGHTS_SNAPSHOTFEATURE_VERSION"             = "disabled"
      "APPLICATIONINSIGHTS_CONNECTION_STRING"           = format("InstrumentationKey=%s;IngestionEndpoint=%s", module.application_insights.instrumentation_key, local.ingestion_endpoint)
      "ApplicationInsightsAgent_EXTENSION_VERSION"      = "~2"
      "DiagnosticServices_EXTENSION_VERSION"            = "disabled"
      "btServiceBusQueueName"                           = data.terraform_remote_state.prod_oasis.outputs.servicebus_queue_name
      "btServiceBusConnectionString"                    = data.terraform_remote_state.prod_oasis.outputs.servicebus_queue_auth_rule_name
      "InstrumentationEngine_EXTENSION_VERSION"         = "disabled"
      "SnapshotDebugger_EXTENSION_VERSION"              = "disabled"
      "XDT_MicrosoftApplicationInsights_BaseExtensions" = "disabled"
      "XDT_MicrosoftApplicationInsights_Mode"           = "default"
      "XDT_MicrosoftApplicationInsights_PreemptSdk"     = "disabled"
    }
  )

  identity {
    type = "SystemAssigned"
  }

  tags = merge(
    local.tags,
    {
      "resource" = "app service"
    },
  )
}

resource "azurerm_monitor_diagnostic_setting" "app_service" {
  name                       = "SendAllToLogAnalytics"
  target_resource_id         = azurerm_app_service.this.id
  log_analytics_workspace_id = data.terraform_remote_state.prod_shared.outputs.log_analytics.id

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
      days    = 0
      enabled = false
    }
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "app_service" {
  app_service_id = azurerm_app_service.this.id
  subnet_id      = azurerm_subnet.app_service.id
}

resource "random_uuid" "web" {}

resource "azuread_application" "web" {
  display_name     = local.application_name_web
  identifier_uris  = [format("https://%s/%s", data.terraform_remote_state.prod_shared.outputs.aad_domain_name, local.application_name_web)]
  owners           = [data.azurerm_client_config.current.object_id]
  sign_in_audience = "AzureADMyOrg"

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
