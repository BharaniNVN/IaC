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

resource "azurerm_log_analytics_workspace" "this" {
  name                = "testloganalytics008"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
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

resource "azurerm_subnet" "fw" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "fw" {
  name                = "AzureFirewall-pip"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "this" {
  name                = "test-firewall"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.fw.id
    public_ip_address_id = azurerm_public_ip.fw.id
  }
}

resource "azurerm_resource_group" "this" {
  name     = "${var.env}-server-rg"
  location = var.location
}

module "alienvault" {
  source = "../"

  resource_group_resource          = azurerm_resource_group.this
  resource_prefix                  = var.env
  virtual_machine_suffix           = ["-alienvault"]
  vm_size                          = "Standard_D2s_v3"
  subnet_resource                  = azurerm_subnet.internal
  log_analytics_workspace_resource = azurerm_log_analytics_workspace.this
  vm_starting_number               = 5
  # dns_servers                      = 
  azure_firewall_resource = azurerm_firewall.this
  vm_starting_ip          = 100
  admin_username          = "testadmin"
  admin_password          = "t3st@dm!nP@%%"
}

output "ip_address" {
  value = module.alienvault.ip_address
}
