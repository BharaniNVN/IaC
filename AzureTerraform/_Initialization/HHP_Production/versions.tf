terraform {
  required_version = ">= 0.13.0"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.7"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}
