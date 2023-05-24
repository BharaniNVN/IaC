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

module "app" {
  source = "../"

  resource_group_resource        = azurerm_resource_group.this
  resource_prefix                = var.env
  virtual_machine_suffix         = ["-app2"]
  subnet_resource                = azurerm_subnet.internal
  dsc_extension_version          = "2.83"
  dsc_storage_container_resource = { "name" = "dsc", "storage_account_name" = "dscterraformtest", "resource_group_name" = data.azurerm_resource_group.this.name }
  dns_servers                    = ["10.1.0.4"]
  vm_starting_ip                 = 15
  vm_size                        = "Standard_D4s_v3"
  admin_username                 = "testadmin"
  admin_password                 = "t3st@dm!nP@%%"
  domain_name                    = "test.com"
  domain_join_account            = "administrator123"
  domain_join_password           = "qpo)fleoc64Gssdopp"
  join_ou                        = "OU=APP,OU=Azure,OU=Servers,DC=test,DC=com"
  batch_job_accounts             = formatlist("%s\\%s", var.domain_netbios_name, [var.service_account, var.ssis_service_account])
  service_accounts               = formatlist("%s\\%s", var.domain_netbios_name, [var.service_account, var.hangfire_service_account])
  local_groups_members           = { "Administrators" = ["TEST\\testgroup"] }
  enable_sql_developer           = true
  enable_ssis                    = true
  enable_oracle_tools            = true
  folders_permissions = {
    format("%s\\%s", var.domain_netbios_name, var.service_account)          = { "FullControl" = ["C:\\TempServiceRead", "C:\\TempServiceFull"] },
    format("%s\\%s", var.domain_netbios_name, var.ssis_service_account)     = { "Read" = ["C:\\TempServiceRead"], "FullControl" : ["C:\\TempServiceFull"] },
    format("%s\\%s", var.domain_netbios_name, var.hangfire_service_account) = { "Read" = ["C:\\TempServiceRead"], "FullControl" = ["C:\\TempServiceFull"] },
  }
  file_shares = [
    { "name" = "caw", "path" = "c:\\TempServiceRead", "changeaccess" = formatlist("%s\\%s", var.domain_netbios_name, [var.service_account, var.ssis_service_account, var.hangfire_service_account]) },
  ]
  sql_aliases = [
    { "target" = "10.0.0.1,1433", "name" = ["Operational"] },
    { "target" = "10.0.0.2,1433", "name" = ["EnvironmentLookup", "Log"] },
    { "target" = "10.0.0.3,1433", "name" = ["AFO", "Hangfire", "prodsql"] },
  ]
  hosts_entries                    = local.hosts_entries
  log_analytics_workspace_resource = azurerm_log_analytics_workspace.this
  azure_devops_extension_version   = "1.27"
  azure_devops_account             = var.azure_devops_account
  azure_devops_project             = var.azure_devops_project
  azure_devops_deployment_group    = "TestGroup"
  azure_devops_agent_tags          = "APP"
  azure_devops_pat_token           = var.azure_devops_pat_token
}
