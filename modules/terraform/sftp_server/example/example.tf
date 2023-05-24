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

resource "azurerm_subnet" "dmz" {
  name                 = "dmz"
  virtual_network_name = azurerm_virtual_network.this.name
  resource_group_name  = azurerm_resource_group.network.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_public_ip" "this" {
  name                = "${var.env}-firewall-pip"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "this" {
  name                = "${var.env}-firewall"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.this.id
  }
}

resource "azurerm_resource_group" "this" {
  name     = "${var.env}-servers-rg"
  location = var.location
}

module "sftp" {
  source = "../"

  resource_group_resource          = azurerm_resource_group.this
  resource_prefix                  = var.env
  virtual_machine_suffix           = ["-sftp"]
  loadbalancer_suffix              = "-alb"
  subnet_resource                  = azurerm_subnet.dmz
  dns_servers                      = ["10.1.0.4"]
  vm_starting_ip                   = 101
  vm_size                          = "Standard_D2s_v3"
  data_disk                        = [{ "name" = "", "type" = "Standard_LRS", "size" = 100, "lun" = 0, "caching" = "None" }]
  dsc_extension_version            = "2.83"
  dsc_storage_container_resource   = { "name" = "dsc", "storage_account_name" = "dscterraformtest", "resource_group_name" = data.azurerm_resource_group.this.name }
  enable_internal_loadbalancer     = true
  lb_ip                            = 100
  lb_rules                         = [{ "probe" = { "Tcp" = 22 }, "rule" = {} }]
  lb_load_distribution             = "SourceIP"
  admin_username                   = "testadmin"
  admin_password                   = "t3st@dm!nP@%%"
  domain_name                      = "test.com"
  domain_join_account              = "administrator123"
  domain_join_password             = "qpo)fleoc64Gssdopp"
  join_ou                          = "OU=General,OU=Azure,OU=Servers,DC=test,DC=com"
  sql_admin_accounts               = ["SQL Admins", "testgroup"]
  sql_sa_password                  = "xiH167kDrO03sHi0"
  sql_port                         = 6789
  sftp_admin_account               = "user1"
  sftp_admin_password              = "DrO03sHi0"
  log_analytics_workspace_resource = azurerm_log_analytics_workspace.this
  azure_firewall_resource          = azurerm_firewall.this
  azure_firewall_public_ip_address = [azurerm_public_ip.this.ip_address, azurerm_public_ip.this.ip_address]
}

output "name" {
  value = module.sftp.name
}

output "fqdn" {
  value = module.sftp.fqdn
}

output "identity" {
  value = module.sftp.identity
}

output "ip_address" {
  value = module.sftp.ip_address
}

output "lb_ip_address" {
  value = module.sftp.lb_ip_address
}

output "name_with_ip_address" {
  value = module.sftp.name_with_ip_address
}

output "fqdn_with_ip_address" {
  value = module.sftp.fqdn_with_ip_address
}
