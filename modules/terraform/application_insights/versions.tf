terraform {
  required_version = ">= 0.12.26"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.71"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
