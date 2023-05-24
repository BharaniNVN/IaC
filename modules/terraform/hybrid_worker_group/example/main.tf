terraform {
  required_version = ">= 0.12.26"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 1.30"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "hwg-example-resources"
  location = "eastus"
}

resource "azurerm_automation_account" "example" {
  name                = "account1"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku_name            = "Basic"
}

resource "azurerm_automation_credential" "example" {
  name                    = "credential1"
  resource_group_name     = azurerm_resource_group.example.name
  automation_account_name = azurerm_automation_account.example.name
  username                = "example_user"
  password                = "example_pwd"
  description             = "This is an example credential"
}

module "hwg" {
  source = "../"

  name                  = ["hwg1", "hwg2"]
  credential_name       = azurerm_automation_credential.example.name
  automation_account_id = azurerm_automation_account.example.id
}

output "hwg_name" {
  value = module.hwg.name
}