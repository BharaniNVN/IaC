variable "api_keys" {
  default = {
    "read_key" = ["read_telemetry"],
    "full_key" = ["full_permissions"]
  }
}

variable "location" {
  default = "East US"
}

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
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

resource "random_pet" "test" {}

resource "azurerm_resource_group" "test" {
  name     = format("%s-rg", random_pet.test.id)
  location = var.location
}

resource "azurerm_log_analytics_workspace" "test" {
  name                = format("%s-la", random_pet.test.id)
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  sku                 = "PerGB2018"
}

module "application_insights" {
  source = "../"

  name                             = format("%s-appi", random_pet.test.id)
  resource_group_resource          = azurerm_resource_group.test
  log_analytics_workspace_resource = azurerm_log_analytics_workspace.test
  api_keys                         = var.api_keys

  web_tests = {
    "test1" = {
      "configuration" = <<-XML
        <WebTest Name="WebTest1" Id="ABD48585-0831-40CB-9069-682EA6BB3583" Timeout="90" >
          <Items>
            <Request Method="GET" Version="1.1" Url="http://google.com" Timeout="60" ParseDependentRequests="True" FollowRedirects="True" RecordResult="True" Cache="False" ExpectedHttpStatusCode="200" />
          </Items>
        </WebTest>
      XML
    }
    "test2" = {
      "geo_locations" = [
        "Central US",
        "East US",
        "North Central US",
        "South Central US",
        "West US",
      ],
      "url" = "http://microsoft.com"
    }
  }
}

output "api_key" {
  value     = module.application_insights.api_key
  sensitive = true
}

output "api_keys" {
  value     = module.application_insights.api_keys
  sensitive = true
}

output "app_id" {
  value = module.application_insights.app_id
}

output "connection_string" {
  value     = module.application_insights.connection_string
  sensitive = true
}

output "id" {
  value = module.application_insights.id
}

output "instrumentation_key" {
  value     = module.application_insights.instrumentation_key
  sensitive = true
}

output "location" {
  value = module.application_insights.location
}

output "name" {
  value = module.application_insights.name
}
