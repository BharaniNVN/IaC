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

data "azurerm_client_config" "current" {}

locals {
  hosts_entries = [
    { "name" = "secure21.careanyware.com", "ip" = cidrhost(azurerm_subnet.dmz.address_prefixes[0], var.afo2_vm_starting_ip) },
    { "name" = "secure22.careanyware.com", "ip" = cidrhost(azurerm_subnet.dmz.address_prefixes[0], var.afo2_vm_starting_ip + 1) },
    { "name" = "secure41.careanyware.com", "ip" = cidrhost(azurerm_subnet.dmz.address_prefixes[0], var.afo4_vm_starting_ip) },
    { "name" = "secure42.careanyware.com", "ip" = cidrhost(azurerm_subnet.dmz.address_prefixes[0], var.afo4_vm_starting_ip + 1) },
    { "name" = "secure51.careanyware.com", "ip" = cidrhost(azurerm_subnet.dmz.address_prefixes[0], var.afo5_vm_starting_ip) },
    { "name" = "secure52.careanyware.com", "ip" = cidrhost(azurerm_subnet.dmz.address_prefixes[0], var.afo5_vm_starting_ip + 1) },
    { "name" = "secure61.careanyware.com", "ip" = cidrhost(azurerm_subnet.dmz.address_prefixes[0], var.afo6_vm_starting_ip) },
    { "name" = "secure62.careanyware.com", "ip" = cidrhost(azurerm_subnet.dmz.address_prefixes[0], var.afo6_vm_starting_ip + 1) },
    { "name" = "interface.careanyware.com", "ip" = cidrhost(azurerm_subnet.dmz.address_prefixes[0], 0) },
    { "name" = "mobileapi.brightree.net", "ip" = cidrhost(azurerm_subnet.dmz.address_prefixes[0], 0) },
    { "name" = "mobileapi2.brightree.net", "ip" = cidrhost(azurerm_subnet.dmz.address_prefixes[0], 0) },
    { "name" = "mobileapi4.brightree.net", "ip" = cidrhost(azurerm_subnet.dmz.address_prefixes[0], 0) },
    { "name" = "login.careanyware.com", "ip" = cidrhost(azurerm_subnet.dmz.address_prefixes[0], 0) },
    { "name" = "extapi.careanyware.com", "ip" = cidrhost(azurerm_subnet.dmz.address_prefixes[0], 0) },
  ]
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

resource "azurerm_storage_account" "this" {
  name                            = substr("${var.env}mxhhpsharesa", 0, 20)
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
  enable_https_traffic_only       = true
  account_kind                    = "StorageV2"

  provisioner "local-exec" {
    command = "az storage account keys renew -g ${self.resource_group_name} -n ${self.name} --key-type kerb --key primary -o none && az storage account keys renew -g ${self.resource_group_name} -n ${self.name} --key-type kerb --key secondary -o none"
  }
}

module "que" {
  source = "../"

  quantity                         = 2
  resource_group_resource          = azurerm_resource_group.this
  resource_prefix                  = var.env
  virtual_machine_suffix           = ["-testque"]
  subnet_resource                  = azurerm_subnet.dmz
  dsc_extension_version            = "2.83"
  dsc_storage_container_resource   = { "name" = "dsc", "storage_account_name" = "dscterraformtest", "resource_group_name" = data.azurerm_resource_group.this.name }
  dns_servers                      = ["10.1.0.4"]
  vm_starting_ip                   = 35
  vm_size                          = "Standard_F4s_v2"
  admin_username                   = "testadmin"
  admin_password                   = "t3st@dm!nP@%%"
  domain_name                      = "test.com"
  domain_join_account              = "administrator123"
  domain_join_password             = "qpo)fleoc64Gssdopp"
  join_ou                          = "OU=QUE,OU=Azure,OU=Servers,DC=test,DC=com"
  iis_folders_with_read_access     = ["C:\\TempIISRead"]
  iis_folders_with_full_access     = ["C:\\TempIISFull"]
  service_folders_with_read_access = ["C:\\TempServiceRead"]
  service_folders_with_full_access = ["C:\\TempServiceFull"]
  service_account_username         = "TEST\\\\svc-web"
  service_account_password         = "zx5&peBV,FE(Dy3F"
  firewall_ports                   = [8000]
  app_pool_account                 = "TEST\\\\svc-web"
  sql_aliases = [
    { "target" = "10.0.0.1,1433", "name" = ["BTHMENET", "Operational"] },
    { "target" = "10.0.0.3,1433", "name" = ["EnvironmentLookup", "Log"] },
    { "target" = "10.0.0.2,1433", "name" = ["Hangfire", "PRODSQL-2"] },
    { "target" = "10.0.0.4,1433", "name" = ["PRODSQL-4"] },
    { "target" = "10.0.0.5,1433", "name" = ["PRODSQL-5"] },
    { "target" = "10.0.0.6,1433", "name" = ["PRODSQL-6"] },
  ]
  hosts_entries                    = local.hosts_entries
  storage_share                    = azurerm_storage_account.this.primary_file_host
  storage_share_access_username    = azurerm_storage_account.this.name
  storage_share_access_password    = azurerm_storage_account.this.primary_access_key
  log_analytics_workspace_resource = azurerm_log_analytics_workspace.this
  azure_devops_extension_version   = "1.27"
  azure_devops_account             = var.azure_devops_account
  azure_devops_project             = var.azure_devops_project
  azure_devops_deployment_group    = "TestGroup"
  azure_devops_agent_tags          = "QUE_WEB,QUE_SVC"
  azure_devops_pat_token           = var.azure_devops_pat_token
}

output "name" {
  value = module.que.name
}

output "fqdn" {
  value = module.que.fqdn
}

output "identity" {
  value = module.que.identity
}

output "ip_address" {
  value = module.que.ip_address
}

output "name_with_ip_address" {
  value = module.que.name_with_ip_address
}

output "fqdn_with_ip_address" {
  value = module.que.fqdn_with_ip_address
}
