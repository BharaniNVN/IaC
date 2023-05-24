
resource "azurerm_key_vault" "keyvault" {
  name                       = "cosdbkeyvault"
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  enabled_for_disk_encryption     = false
  enabled_for_deployment          = false
  enabled_for_template_deployment = false
  purge_protection_enabled        = true

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Create",
      "Get",
    ]

    secret_permissions = [
      "Set",
      "Get",
      "Delete",
      "Purge",
      "Recover"
    ]
  }
}

resource "azurerm_key_vault_secret" "keyvault_secret" {
  count        = length(azurerm_cosmosdb_account.this.connection_strings)
  name         = "AuthenticationServerCosmosDBConnectionString-${count.index}"
  value        = tostring("${azurerm_cosmosdb_account.this.connection_strings[count.index]}")
  key_vault_id = azurerm_key_vault.keyvault.id
}

resource "azurerm_cosmosdb_account" "this" {
  name                = "${local.deprecated_prefix}-cosmos"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level       = "Strong"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = azurerm_resource_group.this.location
    failover_priority = 0
  }

  enable_automatic_failover         = false
  is_virtual_network_filter_enabled = true

  virtual_network_rule {
    id = azurerm_subnet.paas.id
  }

  virtual_network_rule {
    id = data.terraform_remote_state.codingcenter_shared.outputs.app_service_subnet.id
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


