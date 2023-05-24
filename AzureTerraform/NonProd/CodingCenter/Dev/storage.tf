
resource "azurerm_storage_account" "this" {
  name                            = "${local.deprecated_prefix}sa"
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  account_kind                    = "StorageV2"
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  enable_https_traffic_only       = true
  min_tls_version                 = "TLS1_2"
  access_tier                     = "Cool"

  

  tags = merge(
    local.tags,
    {
      "resource" = "storage account"
    }
  )

 }

 resource "azurerm_storage_container" "data" {
  name                  = "dev"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"

}

resource "azurerm_storage_account_network_rules" "this" {
  storage_account_id = azurerm_storage_account.this.id

  default_action             = "Deny"
  bypass                     = ["AzureServices"]
  virtual_network_subnet_ids = local.subnet.*
  depends_on = [
    azurerm_storage_container.data
  ]

}