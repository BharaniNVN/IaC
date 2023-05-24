terraform {
  required_version = ">= 0.12.26"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

locals {
  subscription_resource_id = format("/subscriptions/%s", data.azurerm_client_config.current.subscription_id)
}

resource "azurerm_resource_group" "this" {
  name     = "${var.env}-existing-rg"
  location = var.location
}

resource "random_id" "this" {
  byte_length = 4

  keepers = {
    resource_group_id = azurerm_resource_group.this.id
  }
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = format("testloganalytics%s", random_id.this.dec)
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

module "automation" {
  source = "../"

  environment                      = var.env
  environment_prefix               = var.env
  resource_group_name              = "test-group"
  location                         = "South Central US"
  run_as_account_username          = azuread_application.vm_operator.id
  run_as_account_password          = azuread_application_password.vm_operator.value
  timezone                         = "America/New_York"
  start_time                       = "2122-02-20T8:00:00Z"
  stop_time                        = "2122-02-20T19:00:00Z"
  tag_stage1                       = "backend"
  tag_stage1_value                 = "true"
  tag_stage2                       = "test"
  tag_stage2_value                 = "true"
  tag_to_exclude                   = "doNotShutdown"
  tag_to_exclude_value             = "true"
  log_analytics_workspace_resource = azurerm_log_analytics_workspace.this
  tags                             = { "test" = "yeah" }
}
