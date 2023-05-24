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

resource "azurerm_resource_group" "this" {
  name     = "${var.env}-test-rg"
  location = var.location
}

resource "azurerm_virtual_network" "this" {
  name                = "${var.env}-test-vnet"
  location            = azurerm_resource_group.this.location
  address_space       = ["10.0.0.0/16"]
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "shared" {
  name                 = "shared"
  virtual_network_name = azurerm_virtual_network.this.name
  resource_group_name  = azurerm_resource_group.this.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "shared_endpoints" {
  name                                           = "shared-endpoints-subnet"
  virtual_network_name                           = azurerm_virtual_network.this.name
  resource_group_name                            = azurerm_resource_group.this.name
  address_prefixes                               = ["10.0.1.0/24"]
  enforce_private_link_endpoint_network_policies = true
}

# Single instance AWX with Azure database
module "awx" {
  source = "../"

  resource_group_resource              = azurerm_resource_group.this
  resource_prefix                      = var.env
  virtual_machine_suffix               = ["-test"]
  subnet_resource                      = azurerm_subnet.shared
  endpoint_subnet_resource             = azurerm_subnet.shared_endpoints
  admin_username                       = "awx"
  admin_password                       = "t3st@dm!nP@%%"
  awx_admin_username                   = "awx"
  awx_admin_password                   = "t3st@dm!nP@%%"
  awx_secret_key                       = "c7e805a22d79b0514b2ba7b380a8cab91a64cf80b79324779e776ec9c80d4131"
  awx_database_server_username         = "awx"
  awx_database_server_password         = "y5cQPu8uG2S5EUkD"
  awx_database_server_azure_suffix     = "-test-psql"
  awx_database_server_azure_storage_mb = 102400
  # Uncomment when azurerm provider version will be >2.16.0
  # azuread_sql_admins_group             = data.azuread_group.sql_admins
}

# Single instance AWX with local database
# module "awx" {
#   source = "../"
#   resource_group_resource              = azurerm_resource_group.this
#   resource_prefix                      = var.env
#   virtual_machine_suffix               = ["-test"]
#   subnet_resource                      = azurerm_subnet.shared
#   admin_username                       = "awx"
#   admin_password                       = "t3st@dm!nP@%%"
#   awx_admin_username                   = "awx"
#   awx_admin_password                   = "t3st@dm!nP@%%"
#   awx_secret_key                       = "c7e805a22d79b0514b2ba7b380a8cab91a64cf80b79324779e776ec9c80d4131"
#   awx_database_server_type             = "Local"
#   awx_database_server_username         = "awx"
#   awx_database_server_password         = "aJXjXBj4am"
# }

# Single instance AWX with external database
# module "awx" {
#   source = "../"
#   resource_group_resource              = azurerm_resource_group.this
#   resource_prefix                      = var.env
#   virtual_machine_suffix               = ["-test"]
#   subnet_resource                      = azurerm_subnet.shared
#   admin_username                       = "awx"
#   admin_password                       = "t3st@dm!nP@%%"
#   awx_admin_username                   = "awx"
#   awx_admin_password                   = "t3st@dm!nP@%%"
#   awx_secret_key                       = "c7e805a22d79b0514b2ba7b380a8cab91a64cf80b79324779e776ec9c80d4131"
#   awx_database_server_type             = "External"
#   awx_database_server_external_name    = "server.postgres.database.azure.com"
#   awx_database_server_username         = "awx@btawx"
#   awx_database_server_password         = "aJXjXBj4am"
# }

# Uncomment when azurerm provider version will be >2.16.0
# data "azuread_group" "sql_admins" {
#   display_name = "SqlAdmins"
# }

# Uncomment when azurerm provider version will be >2.16.0
# resource "azurerm_postgresql_active_directory_administrator" "awx_database_server_admins" {
#   server_name         = module.awx.hosted_database_server_name
#   resource_group_name = azurerm_resource_group.this
#   login               = data.azuread_group.sql_admins.name
#   tenant_id           = data.azurerm_client_config.current.tenant_id
#   object_id           = data.azuread_group.sql_admins.object_id
# }
