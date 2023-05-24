resource "azurerm_mssql_server" "this" {
  name                         = "${local.deprecated_prefix}-sqlsvr"
  location                     = azurerm_resource_group.this.location
  resource_group_name          = azurerm_resource_group.this.name
  version                      = var.azure_sql_version
  administrator_login          = var.azure_sql_admin
  administrator_login_password = var.azure_sql_admin_pswd
  minimum_tls_version          = "1.2"

  azuread_administrator {
    login_username = data.terraform_remote_state.nonprod_shared.outputs.sql_admins_group.display_name
    object_id      = data.terraform_remote_state.nonprod_shared.outputs.sql_admins_group.object_id
    tenant_id      = data.azurerm_client_config.current.tenant_id
  }

  tags = merge(
    local.tags,
    {
      "resource" = "azure sql server"
    },
  )
}

module "az_sql_audit" {
  source                    = "../../../../modules/terraform/sql_audit"
  sql_server_name           = azurerm_mssql_server.this.name
  resource_group_name       = azurerm_resource_group.this.name
  log_analytics_resource_id = data.terraform_remote_state.nonprod_shared.outputs.log_analytics.id
  eventhub_policy_id        = data.terraform_remote_state.nonprod_shared.outputs.eventhub_policy.id
  eventhub_name             = data.terraform_remote_state.nonprod_shared.outputs.eventhub_name
}

resource "azurerm_mssql_virtual_network_rule" "this" {
  name      = "${local.deprecated_prefix}-sql-vnet-rule"
  server_id = azurerm_mssql_server.this.id
  subnet_id = azurerm_subnet.paas.id
}

resource "azurerm_mssql_firewall_rule" "internal_azure_resources" {
  name             = "${local.deprecated_prefix}-sql-fw-InternalAzure"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_firewall_rule" "office_public_ips" {
  for_each = data.terraform_remote_state.nonprod_shared.outputs.office_public_ip_address

  name             = format("%s-sql-fw-%s", local.deprecated_prefix, each.key)
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = each.value
  end_ip_address   = each.value
}

resource "azurerm_mssql_firewall_rule" "app_service_plan" {
  name             = "${local.deprecated_prefix}-sql-fw-asp"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = cidrhost(data.terraform_remote_state.codingcenter_shared.outputs.app_service_subnet.address_prefixes[0], 0)
  end_ip_address   = cidrhost(data.terraform_remote_state.codingcenter_shared.outputs.app_service_subnet.address_prefixes[0], -1)
}

resource "azurerm_mssql_database" "this" {
  name        = "${local.deprecated_prefix}-sqldb"
  server_id   = azurerm_mssql_server.this.id
  create_mode = "Default"
  sku_name    = var.azure_mssql_database_sku_name

  tags = merge(
    local.tags,
    {
      "resource" = "azure sql database"
    },
  )
}

resource "azurerm_monitor_diagnostic_setting" "mssql_database" {
  name                       = "SendSelectedToLogAnalytics"
  target_resource_id         = azurerm_mssql_database.this.id
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
