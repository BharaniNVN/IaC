resource "azurerm_cosmosdb_account" "this" {
  name                = "${local.prefix}-cdba"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 10
    max_staleness_prefix    = 200
  }

  # geo_location {
  #   location          = azurerm_resource_group.this.location
  #   failover_priority = 1
  # }

  geo_location {
    location          = azurerm_resource_group.this.location
    failover_priority = 0
  }

  ip_range_filter                   = format("%s,%s,%s", azurerm_windows_web_app.this.possible_outbound_ip_addresses, join(",", values(data.terraform_remote_state.nonprod_shared.outputs.office_public_ip_address)), "104.42.195.92,40.76.54.131,52.176.6.30,52.169.50.45,52.187.184.26")
  enable_automatic_failover         = false
  is_virtual_network_filter_enabled = true

  virtual_network_rule {
    id = azurerm_subnet.paas.id
  }

  virtual_network_rule {
    id = data.terraform_remote_state.oasis_shared.outputs.app_service_subnet.id
  }

  tags = merge(
    local.tags,
    {
      "resource" = "cosmosdb account"
    },
  )
}

resource "azurerm_monitor_diagnostic_setting" "cosmosdb" {
  name                           = "SendSelectedToLogAnalytics"
  target_resource_id             = azurerm_cosmosdb_account.this.id
  log_analytics_destination_type = "AzureDiagnostics"
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.this.id

  dynamic "log" {
    for_each = {
      "CassandraRequests"         = false,
      "DataPlaneRequests"         = false,
      "GremlinRequests"           = false,
      "MongoRequests"             = false,
      "TableApiRequests"          = false,
      "ControlPlaneRequests"      = true,
      "PartitionKeyRUConsumption" = true,
      "PartitionKeyStatistics"    = true,
      "QueryRuntimeStatistics"    = true,
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
    category = "Requests"
    enabled  = false

    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_cosmosdb_sql_database" "this" {
  name                = "OasisCodingStation"
  resource_group_name = azurerm_cosmosdb_account.this.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
}

resource "azurerm_cosmosdb_sql_container" "documents" {
  name                = "Documents"
  resource_group_name = azurerm_cosmosdb_account.this.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  database_name       = azurerm_cosmosdb_sql_database.this.name
  partition_key_path  = "/id"
  throughput          = 400
}

resource "azurerm_cosmosdb_sql_container" "leases" {
  name                = "leases"
  resource_group_name = azurerm_cosmosdb_account.this.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  database_name       = azurerm_cosmosdb_sql_database.this.name
  partition_key_path  = "/id"
  throughput          = 400
}
