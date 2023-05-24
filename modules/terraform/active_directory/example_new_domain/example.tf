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

locals {
  domain_dn = join(",", formatlist("DC=%s", split(".", var.domain_name)))
}

data "azurerm_resource_group" "this" {
  name = "resources-rg"
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.env}-testloganalytics-new"
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
  name     = "${var.env}-dc-rg"
  location = var.location
}

module "active_directory" {
  source = "../"

  quantity                                = var.dc_count
  resource_group_resource                 = azurerm_resource_group.this
  resource_prefix                         = var.env
  virtual_machine_suffix                  = ["-testdc"]
  availability_set_suffix                 = "-dcaz-av"
  boot_diagnostics_storage_account_suffix = "bootdiag"
  vm_size                                 = "Standard_D2s_v3"
  subnet_resource                         = azurerm_subnet.internal
  dsc_extension_version                   = "2.83"
  dsc_storage_container_resource          = { "name" = "dsc", "storage_account_name" = "dscterraformtest", "resource_group_name" = data.azurerm_resource_group.this.name }
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.this
  vm_starting_number                      = 5
  dns_servers                             = [for i in range(var.dc_count) : cidrhost(azurerm_subnet.internal.address_prefixes[0], i + var.dc_starting_ip)]
  vm_starting_ip                          = var.dc_starting_ip
  data_disk                               = [{ "name" = "", "type" = "Standard_LRS", "size" = 10, "lun" = 0, "caching" = "None" }]
  admin_username                          = "testadmin"
  admin_password                          = "t3st@dm!nP@%%"
  domain_name                             = var.domain_name
  domain_admin                            = "administrator123"
  domain_password                         = "qpo)fleoc64Gssdopp"
  domain_join_account                     = "testjoin"
  domain_join_password                    = "2gE3QGbwUv"
  deploy_domain                           = true
  ad_ou = [
    { "path" = local.domain_dn, "name" = ["Servers"] },
    { "path" = "OU=Servers,${local.domain_dn}", "name" = ["Azure"] },
    { "path" = "OU=Azure,OU=Servers,${local.domain_dn}", "name" = ["AFO", "APP", "General", "MsSql", "Oracle", "QUE", "SYNC", "WF"] }
  ]
  dns_forwarders                  = ["1.1.1.1", "1.0.0.1"]
  reverse_dns_zone_names          = distinct([for n in azurerm_virtual_network.this.address_space : join(".", reverse(slice(split(".", split("/", n)[0]), 0, floor(split("/", n)[1] / 8))))])
  custom_script_extension_version = "1.10"
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
