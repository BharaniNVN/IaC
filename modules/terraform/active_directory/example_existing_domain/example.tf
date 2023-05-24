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
  name                = "${var.env}-testloganalytics-existing"
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

resource "azurerm_resource_group" "active_directory" {
  name     = "${var.env}-dc-rg"
  location = var.location
}

module "active_directory" {
  source = "../"

  quantity                                = 2
  resource_group_resource                 = azurerm_resource_group.active_directory
  resource_prefix                         = var.env
  virtual_machine_suffix                  = ["-testdc"]
  availability_set_suffix                 = "-dcaz-av"
  boot_diagnostics_storage_account_suffix = "bootdiag"
  vm_size                                 = "Standard_D2s_v3"
  subnet_resource                         = azurerm_subnet.internal
  dsc_extension_version                   = "2.83"
  dsc_storage_container_resource          = { "name" = "dsc", "storage_account_name" = "dscterraformtest", "resource_group_name" = data.azurerm_resource_group.this.name }
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.this
  vm_starting_number                      = 3
  dns_servers                             = ["10.1.0.4"]
  vm_starting_ip                          = 10
  data_disk                               = [{ "name" = "", "type" = "Standard_LRS", "size" = 20, "lun" = 0, "caching" = "None" }]
  admin_username                          = "testadmin"
  admin_password                          = "t3st@dm!nP@%%"
  domain_name                             = "test.com"
  domain_admin                            = "administrator123"
  domain_password                         = "qpo)fleoc64Gssdopp"
  ad_site                                 = "Azure-DR"
  dns_forwarders                          = ["1.1.1.1", "1.0.0.1"]
  custom_script_extension_version         = "1.10"
}

output "name" {
  value = module.active_directory.name
}

output "fqdn" {
  value = module.active_directory.fqdn
}

output "identity" {
  value = module.active_directory.identity
}

output "ip_address" {
  value = module.active_directory.ip_address
}

output "lb_ip_address" {
  value = module.active_directory.lb_ip_address
}

output "name_with_ip_address" {
  value = module.active_directory.name_with_ip_address
}

output "fqdn_with_ip_address" {
  value = module.active_directory.fqdn_with_ip_address
}

output "dns_servers" {
  value = module.active_directory.dns_servers
}
