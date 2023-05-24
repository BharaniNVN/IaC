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
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_subnet" "dmz" {
  name                 = "dmz"
  virtual_network_name = azurerm_virtual_network.this.name
  resource_group_name  = azurerm_resource_group.network.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_resource_group" "this" {
  name     = "${var.env}-servers-rg"
  location = var.location
}

module "wsus" {
  source = "../"

  resource_group_resource          = azurerm_resource_group.this
  resource_prefix                  = var.env
  virtual_machine_suffix           = ["-wsus"]
  subnet_resource                  = azurerm_subnet.dmz
  dsc_extension_version            = "2.83"
  dsc_storage_container_resource   = { "name" = "dsc", "storage_account_name" = "dscterraformtest", "resource_group_name" = data.azurerm_resource_group.this.name }
  log_analytics_workspace_resource = azurerm_log_analytics_workspace.this
  dns_servers                      = ["10.1.0.4"]
  vm_starting_ip                   = 10
  data_disk                        = [{ "name" = "", "type" = "Standard_LRS", "size" = 20, "lun" = 0, "caching" = "None" }]
  vm_size                          = "Standard_D2s_v3"
  admin_username                   = "testadmin"
  admin_password                   = "t3st@dm!nP@%%"
  domain_name                      = "test.com"
  domain_join_account              = "administrator123"
  domain_join_password             = "qpo)fleoc64Gssdopp"
  # upstream_server_name             = "wsus-primary.test.com"
  install_adconnect = true
}

output "update_server" {
  value = module.wsus.update_server
}
