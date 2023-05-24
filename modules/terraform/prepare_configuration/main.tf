locals {
  md5                = filemd5(var.file_path)
  filename           = split(".", basename(var.file_path))[0]
  extension          = split(".", basename(var.file_path))[1]
  hashsum_check      = regexall("_([[:xdigit:]]+)$", local.filename)
  calculated_hashsum = length(local.hashsum_check) == 1 ? local.hashsum_check[0][0] : ""
  target_filename    = length(local.hashsum_check) == 1 ? local.filename : format("%s_%s", local.filename, local.md5)
  target_file        = format("%s.%s", local.target_filename, local.extension)
}

data "azurerm_storage_account" "this" {
  name                = var.storage_container_resource["storage_account_name"]
  resource_group_name = var.storage_container_resource["resource_group_name"]
}

resource "azurerm_storage_blob" "configuration" {
  for_each = toset(var.vm_name)

  name                   = each.value == "" ? local.target_file : format("%s_%s.%s", local.target_filename, each.value, local.extension)
  storage_account_name   = var.storage_container_resource["storage_account_name"]
  storage_container_name = var.storage_container_resource["name"]
  source                 = var.file_path
  content_type           = "application/x-zip-compressed"
  type                   = "Block"
}

data "azurerm_storage_account_blob_container_sas" "this" {
  connection_string = data.azurerm_storage_account.this.primary_connection_string
  container_name    = var.storage_container_resource["name"]
  https_only        = true

  start  = timestamp()
  expiry = timeadd(timestamp(), var.sas_token_validity_period)

  permissions {
    read   = true
    write  = false
    delete = false
    list   = false
    add    = false
    create = false
  }

  depends_on = [var.module_depends_on]
}
