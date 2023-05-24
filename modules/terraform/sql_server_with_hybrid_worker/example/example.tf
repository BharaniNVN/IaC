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

data "azurerm_automation_account" "sqlcopy" {
  name                = "sqlcopy"
  resource_group_name = "tst-resources-rg"
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

resource "azurerm_automation_account" "this" {
  name                = "account1"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "Basic"
}

resource "azurerm_automation_credential" "this" {
  name                    = "credential1"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.this.name
  username                = "example_user"
  password                = "example_pwd"
  description             = "This is an example credential"
}

module "sql" {
  source = "../"

  resource_group_resource        = azurerm_resource_group.this
  resource_prefix                = var.env
  virtual_machine_suffix         = ["-sql2", "-sql5"]
  subnet_resource                = azurerm_subnet.dmz
  dsc_extension_version          = "2.83"
  dsc_storage_container_resource = { "name" = "dsc", "storage_account_name" = "dscterraformtest", "resource_group_name" = data.azurerm_resource_group.this.name }
  dns_servers                    = ["10.1.0.4"]
  vm_starting_ip                 = 5
  data_disk = [
    { "name" = "db", "type" = "Premium_LRS", "size" = 100, "lun" = 0, "caching" = "ReadOnly" },
    { "name" = "logs", "type" = "Standard_LRS", "size" = 10, "lun" = 1, "caching" = "None" },
    { "name" = "temp", "type" = "Premium_LRS", "size" = 100, "lun" = 2, "caching" = "ReadOnly" },
    { "name" = "backup", "type" = "Standard_LRS", "size" = 10, "lun" = 3, "caching" = "None" },
  ]
  vm_size              = "Standard_DS2_v2"
  admin_username       = "testadmin"
  admin_password       = "t3st@dm!nP@%%"
  domain_name          = "test.com"
  domain_join_account  = "administrator123"
  domain_join_password = "qpo)fleoc64Gssdopp"
  join_ou              = "OU=MSSQL,OU=Azure,OU=Servers,DC=test,DC=com"
  local_groups_members = { "Administrators" = ["TEST\\SQL Admins"] }
  sql_iso_path         = "https://proddscstg.blob.core.windows.net/software/MsSql/SQL2017EA/SW_DVD9_NTRL_SQL_Svr_Ent_Core_2017_64Bit_English_OEM_VL_X21-56995.ISO"
  ssms_install_path    = "https://proddscstg.blob.core.windows.net/software/MsSql/SSMS/SSMS-Setup-ENU-2018.3.1.exe"
  sql_admin_accounts   = ["SQL Admins", ".\\testadmin"]
  sql_sa_password      = "xiH167kDrO03sHi0"
  sql_service_user     = "TEST\\\\testuser"
  sql_service_pass     = "ase34%^2nUHppp@11!"
  sql_agent_user       = "TEST\\\\testuser"
  sql_agent_pass       = "ase34%^2nUHppp@11!"
  sql_instance_name    = "MSSQLSERVER"
  sql_port             = 12345
  sql_logins = [
    { "name" = "TEST\\domainuser01", "logintype" = "WindowsUser", "password" = "" },
    { "name" = "TEST\\group01", "logintype" = "WindowsGroup", "password" = "" },
    { "name" = "sqluser01", "logintype" = "SqlLogin", "password" = "password123" },
    { "name" = "sqluser02", "logintype" = "SqlLogin", "password" = "password456" },
  ]
  install_myanalytics_software_pack = true
  integration_runtime_key           = "IR@628b866b-741b-47f9-8006-799e6420c0ab@some-adf@ncu@6lOHIKVUnYM/8QQBiJpzCWr/hlDAKrIguzghNNbgOw8="
  # deployment_agent_account          = "test\\\\administrator123"
  # deployment_agent_password         = "qpo)fleoc64Gssdopp"
  log_analytics_workspace_resource   = azurerm_log_analytics_workspace.this
  azure_devops_extension_version     = "1.27"
  azure_devops_account               = var.azure_devops_account
  azure_devops_project               = var.azure_devops_project
  azure_devops_deployment_group      = "TestGroup"
  azure_devops_agent_tags            = "SQL"
  azure_devops_pat_token             = var.azure_devops_pat_token
  sql_license_type                   = "AHUB"
  automation_account_resource        = data.azurerm_automation_account.sqlcopy
  create_system_assigned_identity    = "true"
  automation_account_credential_name = azurerm_automation_credential.this.name
}

output "name_with_ip_address" {
  value = module.sql.name_with_ip_address
}

output "name_with_ip_address_and_port" {
  value = module.sql.name_with_ip_address_and_port
}
