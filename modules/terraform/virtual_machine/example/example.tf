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

data "azurerm_resource_group" "this" {
  name = "resources-rg"
}

resource "azurerm_resource_group" "network" {
  name     = "${var.env}-network-rg"
  location = var.location
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet"
  location            = azurerm_resource_group.network.location
  address_space       = ["10.0.0.0/22"]
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  virtual_network_name = azurerm_virtual_network.this.name
  resource_group_name  = azurerm_resource_group.network.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_resource_group" "this" {
  name     = "${var.env}-server-rg"
  location = var.location
}

module "vm" {
  source = "../"

  resource_group_resource = azurerm_resource_group.this
  resource_prefix         = var.env
  virtual_machine_suffix  = ["-testvm"]
  vm_size                 = "Standard_D2s_v3"
  subnet_resource         = azurerm_subnet.internal
  vm_starting_number      = 5
  dns_servers             = ["10.1.0.4"]
  vm_starting_ip          = 100
  admin_username          = "testadmin"
  admin_password          = "t3st@dm!nP@%%"
}

output "ostype" {
  value = module.vm.ostype
}

output "first" {
  value = module.vm.first
}

output "name" {
  value = module.vm.name
}

output "id" {
  value = module.vm.id
}

output "ip_address" {
  value = module.vm.ip_address
}

output "lb_ip_address" {
  value = module.vm.lb_ip_address
}

output "name_with_ip_address" {
  value = module.vm.name_with_ip_address
}
