resource "azurerm_storage_account" "function_app" {
  name                            = "${local.prefix}fctappsa"
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
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

resource "azurerm_function_app" "this" {
  name                       = "${local.prefix}-fct-app"
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  app_service_plan_id        = data.terraform_remote_state.oasis_shared.outputs.app_service_plan_id
  storage_account_name       = azurerm_storage_account.function_app.name
  storage_account_access_key = azurerm_storage_account.function_app.primary_access_key
  version                    = "~3"

  app_settings = merge(
    data.external.function_app_appsettings.result,
    {
      "CosmosDBConnection"                      = azurerm_cosmosdb_account.this.connection_strings[0]
      "APPINSIGHTS_INSTRUMENTATIONKEY"          = module.application_insights.instrumentation_key
      "AssessmentQueueConnection"               = azurerm_servicebus_queue_authorization_rule.assessment_oasiscodingstation.primary_connection_string
      "FirstIntelQueueConnection"               = azurerm_servicebus_queue_authorization_rule.firstintel_oasiscodingstation.primary_connection_string
      "AssessmentReviewQueueConnection"         = azurerm_servicebus_queue_authorization_rule.assessment_review_oasiscodingstation.primary_connection_string
      "BTAssessmentCompletedTopicConnection"    = azurerm_servicebus_topic_authorization_rule.recommendations_oasiscodingstation.primary_connection_string
      "HealthcareFirstCompletedTopicConnection" = azurerm_servicebus_topic_authorization_rule.healthcarefirst_oasiscodingstation.primary_connection_string
      "CodingStationAPIEndpoint"                = format("%s/api", local.homepage)
      "FUNCTIONS_WORKER_RUNTIME"                = "dotnet"
    }
  )

  site_config {
    always_on                 = true
    use_32_bit_worker_process = false
    websockets_enabled        = false

    ip_restriction {
      virtual_network_subnet_id = data.terraform_remote_state.nonprod_shared.outputs.agw_subnet_id
    }
  }

  tags = merge(
    local.tags,
    {
      "resource" = "function app"
    },
  )
}

resource "azurerm_app_service_virtual_network_swift_connection" "function_app" {
  app_service_id = azurerm_function_app.this.id
  subnet_id      = data.terraform_remote_state.oasis_shared.outputs.app_service_subnet.id
}
