variable "location" {
  default = "eastus2"
}

terraform {
  required_version = ">= 0.13.0"
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

resource "random_pet" "sendgrid_account" {}

module "sendgrid_account" {
  source = "../../"

  resource_group_name = format("%s-rg", random_pet.sendgrid_account.id)
  location            = var.location
  name                = format("%s-account", random_pet.sendgrid_account.id)
  user_email          = "empty@email.com"
}

output "sendgrid_username" {
  value = module.sendgrid_account.sendgrid_username
}

output "sendgrid_password" {
  value = module.sendgrid_account.sendgrid_password
}

output "sendgrid_servername" {
  value = module.sendgrid_account.sendgrid_servername
}
