terraform {
  required_version = ">= 0.12.26"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 1.30"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "prefix" {
  default = "prfx"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg"
  location = "eastus"
}

resource "azurerm_sql_server" "sql" {
  name                         = "${var.prefix}-sqlsvr"
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  version                      = "12.0"
  administrator_login          = "testadmin"
  administrator_login_password = "Sup@r_strong_password!"
}

resource "azurerm_sql_database" "sqldb" {
  name                             = "${var.prefix}-sqldb"
  resource_group_name              = azurerm_resource_group.rg.name
  location                         = azurerm_resource_group.rg.location
  server_name                      = azurerm_sql_server.sql.name
  create_mode                      = "default"
  edition                          = "standard"
  requested_service_objective_name = "S1"
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = "${var.prefix}-log-analytics-name"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_eventhub_namespace" "alienvault" {
  name                = "${var.prefix}-hhp-namespace"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Basic"
  capacity            = 1
  tags = {
    owner = "vviet"
  }
}

resource "azurerm_eventhub" "alienvault" {
  name                = "${var.prefix}-hhp-hub"
  namespace_name      = azurerm_eventhub_namespace.alienvault.name
  resource_group_name = azurerm_resource_group.rg.name
  partition_count     = 2
  message_retention   = 1
}

resource "azurerm_eventhub_namespace_authorization_rule" "alienvault" {
  name                = "${var.prefix}-Alienvault"
  namespace_name      = azurerm_eventhub_namespace.alienvault.name
  resource_group_name = azurerm_resource_group.rg.name
  listen              = true
  send                = true
  manage              = true
}

module "az_sql_audit" {
  source                    = "../"
  sql_server_name           = azurerm_sql_server.sql.name
  resource_group_name       = azurerm_resource_group.rg.name
  log_analytics_resource_id = azurerm_log_analytics_workspace.example.id                  # Optional. If provided, then sending logs to log analytics will be enabled.
  eventhub_policy_id        = azurerm_eventhub_namespace_authorization_rule.alienvault.id # Optional. If provided, then sending logs to Event Hub will be enabled.
  eventhub_name             = azurerm_eventhub.alienvault.name                            # Optional. If provided, then sending logs to Event Hub will be enabled. MUST be used together with "eventhub_policy_id"
  # If all 3 optional parameters are not set, the audit will be disabled.
}
