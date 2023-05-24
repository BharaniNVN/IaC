variable "location" {
  default = "eastus2"
}

terraform {
  required_version = ">= 0.13.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "random_pet" "sendgrid_account" {}

resource "azurerm_resource_group" "sendgrid" {
  name     = format("%s-rg", random_pet.sendgrid_account.id)
  location = var.location
}

resource "azurerm_key_vault" "this" {
  name                        = format("%s-kv", random_pet.sendgrid_account.id)
  location                    = azurerm_resource_group.sendgrid.location
  resource_group_name         = azurerm_resource_group.sendgrid.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    certificate_permissions = [
      "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update",
    ]

    key_permissions = [
      "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey",
    ]

    secret_permissions = [
      "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set",
    ]
  }
}

module "sendgrid_account" {
  source = "../../"

  resource_group_resource = azurerm_resource_group.sendgrid
  name                    = format("%s-account", random_pet.sendgrid_account.id)
  key_vault_resource      = azurerm_key_vault.this
}

output "sendgrid_username" {
  value = module.sendgrid_account.sendgrid_username
}

output "sendgrid_password" {
  value = module.sendgrid_account.sendgrid_password
}

output "sendgrid_servername" {
  value = module.sendgrid_account.sendgrid_servername
}
