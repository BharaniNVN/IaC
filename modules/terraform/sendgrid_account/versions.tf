terraform {
  required_version = ">= 0.13.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.30"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
