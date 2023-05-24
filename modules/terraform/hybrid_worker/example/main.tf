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

data "azurerm_virtual_machine" "this" {
  name                = "tst-DC01"
  resource_group_name = "TST-DC01_GROUP"
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

module "hwg" {
  source = "../../hybrid_worker_group"

  name                  = ["hwg1"]
  automation_account_id = azurerm_automation_account.example.id
}

module "hybrid_worker" {
  source = "../"

  worker_group_name           = module.hwg.name[0]
  automation_account_name     = azurerm_automation_account.example.name
  automation_account_rg_name  = azurerm_automation_account.example.resource_group_name
  virtual_machine_resource    = [data.azurerm_virtual_machine.this]
  automation_account_endpoint = azurerm_automation_account.example.dsc_server_endpoint
}
