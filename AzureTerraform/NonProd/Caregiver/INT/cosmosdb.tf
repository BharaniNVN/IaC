# DB will be configured later

# resource "azurerm_cosmosdb_account" "this" {
#   name                = "${local.prefix}-caregiver"
#   location            = azurerm_resource_group.this.location
#   resource_group_name = azurerm_resource_group.this.name
#   offer_type          = "Standard"
#   kind                = "GlobalDocumentDB"

#   enable_automatic_failover = true

#   capabilities {
#     name = "EnableAggregationPipeline"
#   }

#   capabilities {
#     name = "mongoEnableDocLevelTTL"
#   }

#   capabilities {
#     name = "MongoDBv3.4"
#   }

#   consistency_policy {
#     consistency_level       = "BoundedStaleness"
#     max_interval_in_seconds = 10
#     max_staleness_prefix    = 200
#   }

#   geo_location {
#     location          = var.failover_location
#     failover_priority = 1
#   }

#   geo_location {
#     location          = azurerm_resource_group.this.location
#     failover_priority = 0
#   }
# }

# resource "azurerm_cosmosdb_mongo_database" "this" {
#   name                = "${local.prefix}-caregiver"
#   resource_group_name = azurerm_resource_group.this.name
#   account_name        = azurerm_cosmosdb_account.this.name
#   throughput          = 400
# }

# resource "azurerm_cosmosdb_mongo_collection" "this" {
#   name                = "${local.prefix}-caregiver"
#   resource_group_name = azurerm_resource_group.this.name
#   account_name        = azurerm_cosmosdb_account.this.name
#   database_name       = azurerm_cosmosdb_mongo_database.this.name

#   default_ttl_seconds = "777"
#   shard_key           = "uniqueKey"
#   throughput          = 400
# }
