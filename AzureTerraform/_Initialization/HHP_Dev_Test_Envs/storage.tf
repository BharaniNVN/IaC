resource "azurerm_resource_group" "this" {
  name     = "${var.env}Terraform-rg"
  location = var.location

  tags = merge(
    local.tags,
    {
      "resource" = "resource group"
    },
  )
}

resource "azurerm_storage_account" "this" {
  name                            = "${local.prefix}sa"
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  account_tier                    = "Standard"
  account_kind                    = "BlobStorage"
  account_replication_type        = "GRS"
  allow_nested_items_to_be_public = false
  enable_https_traffic_only       = true
  min_tls_version                 = "TLS1_2"

  blob_properties {
    container_delete_retention_policy {
      days = 30
    }

    delete_retention_policy {
      days = 30
    }
  }

  tags = merge(
    local.tags,
    {
      "resource" = "storage account"
    },
  )
}

resource "azurerm_storage_container" "init" {
  name                  = "terraform-init"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "states" {
  name                  = "terraform-states"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_management_lock" "storage_account" {
  name       = "Terraform States"
  scope      = azurerm_storage_account.this.id
  lock_level = "CanNotDelete"
  notes      = "Locked because it's needed by a Terraform application."
}
