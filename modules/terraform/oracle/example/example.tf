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

module "oracle" {
  source = "../"

  resource_group_resource        = azurerm_resource_group.this
  resource_prefix                = var.env
  virtual_machine_suffix         = ["-orasrv2", "-orasrv22"]
  subnet_resource                = azurerm_subnet.internal
  dsc_extension_version          = "2.83"
  dsc_storage_container_resource = { name = "dsc", storage_account_name = "dscterraformtest", resource_group_name = data.azurerm_resource_group.this.name }
  dns_servers                    = ["10.1.0.4"]
  vm_size                        = "Standard_D8s_v4"
  vm_starting_ip                 = 66
  image_sku                      = "2012-R2-Datacenter"
  data_disk = [
    { name = "db", type = "Premium_LRS", size = 100, lun = 0, "caching" = "ReadOnly" },
    { name = "backup", type = "Standard_LRS", size = 10, lun = 1, "caching" = "None" },
  ]
  admin_username        = "testadmin"
  admin_password        = "t3st@dm!nP@%%"
  domain_name           = "test.com"
  domain_join_account   = "administrator123"
  domain_join_password  = "qpo)fleoc64Gssdopp"
  join_ou               = "OU=ORACLE,OU=Azure,OU=Servers,DC=test,DC=com"
  local_groups_members  = { "Administrators" = ["TEST\\Oracle Admins"] }
  firewall_ports        = [1521]
  oracle_service_user   = "oracle-svc"
  oracle_service_pswd   = "5tr0ng_Pas5w0rd333"
  oracle_sys_pswd       = "anoth3r_5trong_paSSw0rd" # Passwords may contain only alphanumeric characters from the chosen database character set, underscore (_), dollar sign ($), or pound sign (#).
  oracle_global_db_name = "orcl"
  oracle_install_files = [
    "https://proddscstg.blob.core.windows.net/software/Oracle/OracleDatabase12c/winx64_12102_SE2_database_1of2.zip",
    "https://proddscstg.blob.core.windows.net/software/Oracle/OracleDatabase12c/winx64_12102_SE2_database_2of2.zip",
  ]
  oracle_product_name    = "Oracle 12c"
  oracle_product_version = "12.1.0"
  # deployment_agent_account         = "test\\\\administrator123"
  # deployment_agent_password        = "qpo)fleoc64Gssdopp"
  log_analytics_workspace_resource = azurerm_log_analytics_workspace.this
  azure_devops_extension_version   = "1.27"
  azure_devops_account             = var.azure_devops_account
  azure_devops_project             = var.azure_devops_project
  azure_devops_deployment_group    = "TestGroup"
  azure_devops_agent_tags          = "ORACLE"
  azure_devops_pat_token           = var.azure_devops_pat_token
}
