terraform {
  required_version = ">= 0.12.26"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.7"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.20.0" # https://github.com/hashicorp/terraform-provider-azurerm/issues/18210#issuecomment-1242232190
    }
    dns = {
      source  = "hashicorp/dns"
      version = "~> 3.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
