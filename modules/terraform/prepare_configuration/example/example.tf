terraform {
  required_version = ">= 0.12.26"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "external" {}

resource "azurerm_resource_group" "this" {
  name     = "resources-rg"
  location = "North Central US"
}

resource "azurerm_storage_account" "this" {
  name                      = "dscterraformtest"
  resource_group_name       = azurerm_resource_group.this.name
  location                  = azurerm_resource_group.this.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
}

resource "azurerm_storage_container" "this" {
  name                  = "dsc"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

module "prepare_configuration" {
  source = "../"

  vm_name                    = ["dc1", "dc2", ""]
  file_path                  = "test.zip"
  storage_container_resource = merge(azurerm_storage_container.this, { "resource_group_name" = azurerm_resource_group.this.name })
}

output "token" {
  value = module.prepare_configuration.sas_token
}

output "url" {
  value = module.prepare_configuration.url
}

output "md5" {
  value = module.prepare_configuration.hashsum
}
