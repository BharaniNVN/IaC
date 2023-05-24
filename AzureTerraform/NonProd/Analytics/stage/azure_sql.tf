resource "azurerm_sql_server" "analytics" {
  name                         = "${local.deprecated_prefix}-sql"
  resource_group_name          = azurerm_resource_group.analytics.name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.azure_sql_admin_user
  administrator_login_password = var.azure_sql_admin_pswd

  tags = merge(
    local.tags,
    {
      "resource" = "azure sql server"
    },
  )
}

module "az_sql_audit" {
  source                    = "../../../../modules/terraform/sql_audit"
  sql_server_name           = azurerm_sql_server.analytics.name
  resource_group_name       = azurerm_resource_group.analytics.name
  log_analytics_resource_id = data.terraform_remote_state.nonprod_shared.outputs.log_analytics.id
  eventhub_policy_id        = data.terraform_remote_state.nonprod_shared.outputs.eventhub_policy.id
  eventhub_name             = data.terraform_remote_state.nonprod_shared.outputs.eventhub_name
}

resource "azurerm_sql_database" "analytics" {
  name                             = "${local.deprecated_prefix}-db"
  resource_group_name              = azurerm_resource_group.analytics.name
  location                         = var.location
  server_name                      = azurerm_sql_server.analytics.name
  max_size_bytes                   = 107374182400
  requested_service_objective_name = "S2"
  edition                          = "Standard"

  tags = merge(
    local.tags,
    {
      "resource" = "azure sql database"
    },
  )
}

resource "azurerm_monitor_diagnostic_setting" "analytics_stage_sqldb" {
  name               = "SendSelectedToLogAnalytics"
  target_resource_id = azurerm_sql_database.analytics.id

  log_analytics_workspace_id = data.terraform_remote_state.nonprod_shared.outputs.log_analytics.id

  dynamic "log" {
    for_each = {
      "AutomaticTuning"             = false,
      "Blocks"                      = true,
      "DatabaseWaitStatistics"      = true,
      "Deadlocks"                   = true,
      "DevOpsOperationsAudit"       = true,
      "Errors"                      = true,
      "QueryStoreRuntimeStatistics" = true,
      "QueryStoreWaitStatistics"    = true,
      "SQLInsights"                 = true,
      "SQLSecurityAuditEvents"      = true,
      "Timeouts"                    = true,
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

  dynamic "metric" {
    for_each = ["Basic", "InstanceAndAppAdvanced", "WorkloadManagement"]

    content {
      category = metric.value
      enabled  = false

      retention_policy {
        enabled = false
      }
    }
  }
}

resource "azurerm_mssql_elasticpool" "analytics" {
  name                = "${local.deprecated_prefix}-epool"
  resource_group_name = azurerm_resource_group.analytics.name
  location            = var.location
  server_name         = azurerm_sql_server.analytics.name
  max_size_gb         = 100

  sku {
    name     = "StandardPool"
    tier     = "Standard"
    capacity = 50
  }

  per_database_settings {
    min_capacity = 0
    max_capacity = 50
  }

  tags = merge(
    local.tags,
    {
      "resource" = "elastic pool"
    },
  )
}

resource "azurerm_sql_active_directory_administrator" "ad_admin" {
  server_name         = azurerm_sql_server.analytics.name
  resource_group_name = azurerm_resource_group.analytics.name
  login               = data.terraform_remote_state.nonprod_shared.outputs.sql_admins_group.display_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.terraform_remote_state.nonprod_shared.outputs.sql_admins_group.object_id
}

resource "azurerm_sql_virtual_network_rule" "sql_vnet_rule" {
  name                = "${local.deprecated_prefix}-sql-vnet-rule"
  resource_group_name = azurerm_resource_group.analytics.name
  server_name         = azurerm_sql_server.analytics.name
  subnet_id           = azurerm_subnet.analytics.id
}

resource "azurerm_sql_firewall_rule" "internal_azure_resources" {
  name                = "${local.deprecated_prefix}-sql-fw-InternalAzure"
  resource_group_name = azurerm_resource_group.analytics.name
  server_name         = azurerm_sql_server.analytics.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_sql_firewall_rule" "offices_and_contractors_public_ips" {
  for_each = data.terraform_remote_state.nonprod_shared.outputs.office_public_ip_address

  name                = format("%s-sql-fw-%s", local.deprecated_prefix, each.key)
  resource_group_name = azurerm_resource_group.analytics.name
  server_name         = azurerm_sql_server.analytics.name
  start_ip_address    = each.value
  end_ip_address      = each.value
}
