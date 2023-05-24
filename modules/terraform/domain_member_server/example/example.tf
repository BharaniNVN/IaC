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

resource "azurerm_resource_group" "this" {
  name     = "${var.env}-servers-rg"
  location = var.location
}

module "member" {
  source = "../"

  resource_group_resource          = azurerm_resource_group.this
  resource_prefix                  = var.env
  virtual_machine_suffix           = ["-mmbr2"]
  subnet_resource                  = azurerm_subnet.internal
  dsc_extension_version            = "2.83"
  dsc_storage_container_resource   = { "name" = "dsc", "storage_account_name" = "dscterraformtest", "resource_group_name" = data.azurerm_resource_group.this.name }
  dns_servers                      = ["10.1.0.4"]
  vm_starting_ip                   = 15
  vm_size                          = "Standard_D4s_v3"
  admin_username                   = "testadmin"
  admin_password                   = "t3st@dm!nP@%%"
  domain_name                      = "test.com"
  domain_join_account              = "administrator123"
  domain_join_password             = "qpo)fleoc64Gssdopp"
  join_ou                          = "OU=Azure,OU=Servers,DC=test,DC=com"
  local_groups_members             = { "Administrators" = ["TEST\\testgroup"] }
  log_analytics_workspace_resource = azurerm_log_analytics_workspace.this
  azure_devops_extension_version   = "1.27"
  azure_devops_account             = var.azure_devops_account
  azure_devops_project             = var.azure_devops_project
  azure_devops_deployment_group    = "TestGroup"
  azure_devops_agent_tags          = "MMBR"
  azure_devops_pat_token           = var.azure_devops_pat_token
}
