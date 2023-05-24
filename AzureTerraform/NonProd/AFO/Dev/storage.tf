resource "azurerm_storage_account" "this" {
  name                            = substr("${local.prefix}mxhhpsa", 0, 20)
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

  provisioner "local-exec" {
    command = "az storage account keys renew -g ${self.resource_group_name} -n ${self.name} --key-type kerb --key primary -o none && az storage account keys renew -g ${self.resource_group_name} -n ${self.name} --key-type kerb --key secondary -o none"
  }
}

resource "azurerm_storage_share" "this" {
  name                 = "celltrak"
  storage_account_name = azurerm_storage_account.this.name
  quota                = 50

  depends_on = [data.external.azure_devops_agent_ip]
}

resource "azurerm_storage_share_directory" "root" {
  name                 = "CompletedVisits"
  share_name           = azurerm_storage_share.this.name
  storage_account_name = azurerm_storage_account.this.name
}

resource "azurerm_storage_share_directory" "error" {
  name                 = "CompletedVisits/Error"
  share_name           = azurerm_storage_share.this.name
  storage_account_name = azurerm_storage_share_directory.root.storage_account_name
}

resource "azurerm_storage_account_network_rules" "this" {
  storage_account_id = azurerm_storage_account.this.id

  default_action             = "Deny"
  ip_rules                   = []
  virtual_network_subnet_ids = [azurerm_subnet.dmz.id]
  bypass                     = ["Logging"]

  depends_on = [azurerm_storage_share_directory.error]
}

module "blob" {
  source = "../../../../modules/terraform/private_endpoint"

  resource_group_resource = azurerm_resource_group.this
  subnet_resource         = azurerm_subnet.dmz
  resource                = azurerm_storage_account.this
  endpoint                = "blob"
  ip_index                = 20
  tags                    = local.tags
}

module "file" {
  source = "../../../../modules/terraform/private_endpoint"

  resource_group_resource = azurerm_resource_group.this
  subnet_resource         = azurerm_subnet.dmz
  resource                = azurerm_storage_account.this
  endpoint                = "file"
  ip_index                = 21
  tags                    = local.tags
  module_depends_on       = [module.blob]
}
