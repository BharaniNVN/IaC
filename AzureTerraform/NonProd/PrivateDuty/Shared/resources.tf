resource "azurerm_resource_group" "this" {
  name     = "${local.prefix}-rg"
  location = var.location

  tags = merge(
    local.tags,
    {
      "resource" = "resource group"
    },
  )
}

resource "azurerm_storage_account" "this" {
  name                            = "${local.prefix}mxhhpbaksa"
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  account_tier                    = "Standard"
  account_kind                    = "StorageV2"
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

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_management_policy" "db_backups" {
  storage_account_id = azurerm_storage_account.this.id

  dynamic "rule" {
    for_each = var.db_backups_environments

    content {
      name    = format("%s-FullBackupLifecycle", rule.key)
      enabled = true

      filters {
        prefix_match = rule.value
        blob_types   = ["blockBlob"]
      }

      actions {
        base_blob {
          delete_after_days_since_modification_greater_than = 15
        }
      }
    }
  }
}

resource "azurerm_management_lock" "db_backups" {
  name       = "DB backups storage account lock"
  scope      = azurerm_storage_account.this.id
  lock_level = "CanNotDelete"
  notes      = "Locked for storing DB backups."
}

resource "azurerm_storage_container" "db_backups" {
  for_each = var.db_backups_environments

  name                  = each.key
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_user_assigned_identity" "db_backups" {
  name                = "db-backups-uai"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  tags = merge(
    local.tags,
    {
      "resource" = "user assigned identity"
    },
  )
}

resource "azurerm_role_assignment" "sql_storage_data_contrib_ra" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.db_backups.principal_id
}
