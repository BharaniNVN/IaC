resource "azurerm_resource_group" "this" {
  name     = "${local.deprecated_prefix}-rg"
  location = var.location

  tags = merge(
    local.tags,
    {
      "resource" = "resource group"
    },
  )
}

resource "azurerm_storage_account" "this" {
  name                            = "${local.deprecated_prefix}sa"
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  account_kind                    = "StorageV2"
  account_tier                    = "Standard"
  account_replication_type        = "GRS"
  allow_nested_items_to_be_public = false
  enable_https_traffic_only       = true
  min_tls_version                 = "TLS1_2"

  network_rules {
    default_action = "Deny"
    bypass         = ["Logging"]
    ip_rules       = [data.terraform_remote_state.prod_shared.outputs.office_public_ip_address["Peak10Raleigh"]]
  }

  tags = merge(
    local.tags,
    {
      "resource" = "storage account"
    },
  )

  # We explicitly prevent destruction using terraform. Remove this only if you really know what you're doing.
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_resource_group_template_deployment" "file_share" {
  name                = "${local.deprecated_prefix}-fileshare"
  resource_group_name = azurerm_resource_group.this.name
  deployment_mode     = "Incremental"
  template_content    = file("./fileshare.json")

  parameters_content = jsonencode({
    "fileShareName"      = { "value" = join(",", var.file_shares) },
    "storageAccountName" = { "value" = azurerm_storage_account.this.name },
  })

  tags = merge(
    local.tags,
    {
      "resource" = "resource group template deployment"
    },
  )
}

resource "azurerm_private_endpoint" "file" {
  name                = "${local.deprecated_prefix}pe-file"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = local.dmz_subnet_id

  private_service_connection {
    name                           = "${local.deprecated_prefix}psc-file"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "blob" {
  name                = "${local.deprecated_prefix}pe-blob"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = local.dmz_subnet_id

  private_service_connection {
    name                           = "${local.deprecated_prefix}psc-blob"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}
