resource "azurerm_resource_group" "onprem_db_backups" {
  name     = "${local.deprecated_prefix}-onpremdbbackups-rg"
  location = var.location

  tags = merge(
    local.tags,
    {
      "resource" = "resource group"
    },
  )
}

resource "azurerm_storage_account" "onprem_db_backups" {
  for_each = var.onprem_db_backup_environments

  name                            = "mxhhp${each.key}onprembaksa"
  resource_group_name             = azurerm_resource_group.onprem_db_backups.name
  location                        = azurerm_resource_group.onprem_db_backups.location
  account_tier                    = "Standard"
  account_kind                    = "BlobStorage"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
  enable_https_traffic_only       = true
  min_tls_version                 = "TLS1_2"

  network_rules {
    default_action = "Deny"

    virtual_network_subnet_ids = [
      azurerm_subnet.cawprod_subnet.id
    ]
  }
}

resource "azurerm_storage_management_policy" "onprem_db_backups" {
  for_each = var.onprem_db_backup_environments

  storage_account_id = azurerm_storage_account.onprem_db_backups[each.key].id

  rule {
    name    = "FullBackupLifecycle"
    enabled = true

    filters {
      prefix_match = each.value
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = 13
        delete_after_days_since_modification_greater_than       = 70
      }
    }
  }
}
# To be combined in one resource in 0.13 and add dns names creation
module "blob_s" {
  source = "../../../modules/terraform/private_endpoint"

  resource_group_resource = azurerm_resource_group.onprem_db_backups
  subnet_resource         = azurerm_subnet.cawprod_subnet
  resource                = azurerm_storage_account.onprem_db_backups[keys(var.onprem_db_backup_environments)[6]]
  endpoint                = "blob"
  ip_index                = 8
  tags                    = local.tags
}

module "blob_2" {
  source = "../../../modules/terraform/private_endpoint"

  resource_group_resource = azurerm_resource_group.onprem_db_backups
  subnet_resource         = azurerm_subnet.cawprod_subnet
  resource                = azurerm_storage_account.onprem_db_backups[keys(var.onprem_db_backup_environments)[0]]
  endpoint                = "blob"
  ip_index                = 9
  tags                    = local.tags
  module_depends_on       = [module.blob_s]
}

module "blob_4" {
  source = "../../../modules/terraform/private_endpoint"

  resource_group_resource = azurerm_resource_group.onprem_db_backups
  subnet_resource         = azurerm_subnet.cawprod_subnet
  resource                = azurerm_storage_account.onprem_db_backups[keys(var.onprem_db_backup_environments)[1]]
  endpoint                = "blob"
  ip_index                = 10
  tags                    = local.tags
  module_depends_on       = [module.blob_2]
}

module "blob_5" {
  source = "../../../modules/terraform/private_endpoint"

  resource_group_resource = azurerm_resource_group.onprem_db_backups
  subnet_resource         = azurerm_subnet.cawprod_subnet
  resource                = azurerm_storage_account.onprem_db_backups[keys(var.onprem_db_backup_environments)[2]]
  endpoint                = "blob"
  ip_index                = 11
  tags                    = local.tags
  module_depends_on       = [module.blob_4]
}

module "blob_6" {
  source = "../../../modules/terraform/private_endpoint"

  resource_group_resource = azurerm_resource_group.onprem_db_backups
  subnet_resource         = azurerm_subnet.cawprod_subnet
  resource                = azurerm_storage_account.onprem_db_backups[keys(var.onprem_db_backup_environments)[3]]
  endpoint                = "blob"
  ip_index                = 12
  tags                    = local.tags
  module_depends_on       = [module.blob_5]
}

module "blob_7" {
  source = "../../../modules/terraform/private_endpoint"

  resource_group_resource = azurerm_resource_group.onprem_db_backups
  subnet_resource         = azurerm_subnet.cawprod_subnet
  resource                = azurerm_storage_account.onprem_db_backups[keys(var.onprem_db_backup_environments)[4]]
  endpoint                = "blob"
  ip_index                = 13
  tags                    = local.tags
  module_depends_on       = [module.blob_6]
}

module "blob_8" {
  source = "../../../modules/terraform/private_endpoint"

  resource_group_resource = azurerm_resource_group.onprem_db_backups
  subnet_resource         = azurerm_subnet.cawprod_subnet
  resource                = azurerm_storage_account.onprem_db_backups[keys(var.onprem_db_backup_environments)[5]]
  endpoint                = "blob"
  ip_index                = 14
  tags                    = local.tags
  module_depends_on       = [module.blob_7]
}
