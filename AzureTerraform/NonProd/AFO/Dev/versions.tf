terraform {
  required_version = ">= 0.12.26"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.7"
    }
    ### Terraform plan with azurerm_dns_*_record fails when parsing existing dns record with azurerm 3.19.0
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.18.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
