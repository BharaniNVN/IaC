resource "azurerm_application_insights" "this" {
  name                = "${local.prefix}-ai"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.this.id
  tags = merge(
    local.tags,
    {
      "resource" = "app insights"
    },
  )
}

resource "azurerm_application_insights" "dev_automation_api" {
  name                = "${var.dev_automationapi_tf_name}-ai"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.this.id
  tags = merge(
    local.tags,
    {
      "resource" = "app insights"
    },
  )
}

resource "azurerm_storage_account" "this" {
  name                      = "${local.prefix}sa"
  resource_group_name       = azurerm_resource_group.this.name
  location                  = azurerm_resource_group.this.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"

  tags = merge(
    local.tags,
    {
      "resource" = "storage account"
    },
  )
}

resource "azurerm_storage_account" "dev_automation_api" {
  name                      = "${var.dev_automationapi_tf_name}sa"
  resource_group_name       = azurerm_resource_group.this.name
  location                  = azurerm_resource_group.this.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"

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
  app_service_plan_id        = data.terraform_remote_state.orchestration_shared.outputs.app_service_plan_id
  storage_account_name       = azurerm_storage_account.this.name
  storage_account_access_key = azurerm_storage_account.this.primary_access_key
  https_only                 = true
  version                    = "~3"
  app_settings = {
    WEBSITE_RUN_FROM_PACKAGE              = "1"
    FUNCTIONS_WORKER_RUNTIME              = "dotnet"
    APPINSIGHTS_INSTRUMENTATIONKEY        = azurerm_application_insights.this.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.this.connection_string
  }
  connection_string {
    name  = "GlobalSettingDataBase"
    value = local.connection_string
    type  = "SQLServer"
  }

  tags = merge(
    local.tags,
    {
      "resource" = "function app"
    },
  )

  site_config {
    cors {
      allowed_origins = ["https://dev.azure.com"]
    }
    always_on = true
  }
}

resource "azurerm_function_app" "dev_automation_api" {
  name                       = "${var.dev_automationapi_tf_name}-fct-app"
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  app_service_plan_id        = data.terraform_remote_state.orchestration_shared.outputs.app_service_plan_id
  storage_account_name       = azurerm_storage_account.dev_automation_api.name
  storage_account_access_key = azurerm_storage_account.dev_automation_api.primary_access_key
  https_only                 = true
  version                    = "~3"
  app_settings = {
    WEBSITE_RUN_FROM_PACKAGE              = "1"
    FUNCTIONS_WORKER_RUNTIME              = "dotnet"
    APPINSIGHTS_INSTRUMENTATIONKEY        = azurerm_application_insights.dev_automation_api.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.dev_automation_api.connection_string
  }
  connection_string {
    name  = "GlobalSettingDataBaseConnectionString"
    value = local.connection_string_automation_api
    type  = "SQLServer"
  }

  connection_string {
    name  = "ClinicalDataBaseConnectionString"
    value = local.clinical_connection_string_automation_api
    type  = "SQLServer"
  }

  tags = merge(
    local.tags,
    {
      "resource" = "function app"
    },
  )

  site_config {
    cors {
      allowed_origins = ["https://dev.azure.com"]
    }
    always_on = true
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "function_app" {
  app_service_id = azurerm_function_app.this.id
  subnet_id      = data.terraform_remote_state.orchestration_shared.outputs.app_service_subnet.id
}

resource "azurerm_app_service_virtual_network_swift_connection" "dev_automation_api_function_app" {
  app_service_id = azurerm_function_app.dev_automation_api.id
  subnet_id      = data.terraform_remote_state.orchestration_shared.outputs.app_service_subnet.id
}