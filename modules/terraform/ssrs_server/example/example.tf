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

resource "azurerm_key_vault" "this" {
  name                            = "${var.env}-keyvault-test"
  location                        = azurerm_resource_group.network.location
  resource_group_name             = azurerm_resource_group.network.name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  enabled_for_disk_encryption     = true
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  sku_name                        = "standard"
}

resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  certificate_permissions = [
    "Create",
    "Delete",
    "DeleteIssuers",
    "Get",
    "GetIssuers",
    "Import",
    "List",
    "ListIssuers",
    "ManageContacts",
    "ManageIssuers",
    "Purge",
    "SetIssuers",
    "Update",
  ]

  key_permissions = [
    "Backup",
    "Create",
    "Decrypt",
    "Delete",
    "Encrypt",
    "Get",
    "Import",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Sign",
    "UnwrapKey",
    "Update",
    "Verify",
    "WrapKey",
  ]

  secret_permissions = [
    "Backup",
    "Delete",
    "Get",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Set",
  ]
}

resource "azurerm_key_vault_certificate" "wildcard_certificate_1" {
  name         = "wildcard-certificate-1"
  key_vault_id = azurerm_key_vault_access_policy.terraform.key_vault_id

  certificate {
    contents = filebase64("wildcard_certificate_1_new.pfx")
    password = var.certificate_password_brightree
  }

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = false
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }
  }
}

resource "azurerm_user_assigned_identity" "key_vault_certificates" {
  name                = format("%s-key-vault-certificates-uai", var.env)
  resource_group_name = azurerm_resource_group.network.name
  location            = azurerm_resource_group.network.location
}

resource "azurerm_key_vault_access_policy" "key_vault_certificates" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = azurerm_user_assigned_identity.key_vault_certificates.tenant_id
  object_id    = azurerm_user_assigned_identity.key_vault_certificates.principal_id

  secret_permissions = [
    "Get",
    "List",
  ]
}

resource "azurerm_resource_group" "this" {
  name     = "${var.env}-servers-rg"
  location = var.location
}

module "sql" {
  source = "../../sql_server"

  resource_group_resource        = azurerm_resource_group.this
  resource_prefix                = var.env
  virtual_machine_suffix         = ["-sql2"]
  subnet_resource                = azurerm_subnet.internal
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
  sql_iso_path         = "https://proddscstg.blob.core.windows.net/software/MsSql/SQL2019EA/SW_DVD9_NTRL_SQL_Svr_Ent_Core_2019Dec2019_64Bit_English_OEM_VL_X22-22120.ISO"
  ssms_install_path    = "https://proddscstg.blob.core.windows.net/software/MsSql/SSMS/SSMS-Setup-ENU.18.10.exe"
  sql_admin_accounts   = ["SQL Admins", "testuser", ".\\testadmin"]
  sql_sa_password      = "xiH167kDrO03sHi0"
  sql_service_user     = "TEST\\\\testuser"
  sql_service_pass     = "ase34%^2nUHppp@11!"
  sql_agent_user       = "TEST\\\\testuser"
  sql_agent_pass       = "ase34%^2nUHppp@11!"
  sql_instance_name    = "MSSQLSERVER"
  sql_port             = 12345
}

module "ssrs" {
  source = "../"

  resource_group_resource          = azurerm_resource_group.this
  resource_prefix                  = var.env
  virtual_machine_suffix           = ["-ssrs"]
  subnet_resource                  = azurerm_subnet.internal
  user_assigned_identity_ids       = [azurerm_user_assigned_identity.key_vault_certificates.id]
  certificate_urls                 = [azurerm_key_vault_certificate.wildcard_certificate_1.secret_id]
  key_vault_extension_version      = { "windows" = "1.0", "linux" = "2.0" }
  key_vault_msi_client_id          = azurerm_user_assigned_identity.key_vault_certificates.client_id
  dsc_extension_version            = "2.83"
  dsc_storage_container_resource   = { "name" = "dsc", "storage_account_name" = "dscterraformtest", "resource_group_name" = data.azurerm_resource_group.this.name }
  dns_servers                      = ["10.1.0.4"]
  vm_starting_ip                   = 10
  vm_size                          = "Standard_D4s_v3"
  admin_username                   = "testadmin"
  admin_password                   = "t3st@dm!nP@%%"
  domain_name                      = "test.com"
  domain_join_account              = "administrator123"
  domain_join_password             = "qpo)fleoc64Gssdopp"
  join_ou                          = "OU=MSSQL,OU=Azure,OU=Servers,DC=test,DC=com"
  local_groups_members             = { "Administrators" = ["TEST\\testuser"] }
  ssrs_database_server_name        = values(module.sql.name_with_fqdn_and_port)[0]
  ssrs_database_instance_name      = "MSSQLSERVER"
  ssrs_report_server_reserved_url  = ["http://+:80", "https://+:443"]
  ssrs_reports_reserved_url        = ["http://+:80", "https://+:443"]
  ssrs_service_account             = "TEST\\\\ssrs_svc"
  ssrs_service_password            = "*b~hR}7dM$+hcmu6"
  ssrs_sql_server_account          = "TEST\\\\testuser"
  ssrs_sql_server_password         = "ase34%^2nUHppp@11!"
  ssrs_ssl_certificate_thumbprint  = azurerm_key_vault_certificate.wildcard_certificate_1.thumbprint
  log_analytics_workspace_resource = azurerm_log_analytics_workspace.this
  azure_devops_extension_version   = "1.27"
  azure_devops_account             = var.azure_devops_account
  azure_devops_project             = var.azure_devops_project
  azure_devops_deployment_group    = "TestGroup"
  azure_devops_agent_tags          = "SSRS"
  azure_devops_pat_token           = var.azure_devops_pat_token
}
