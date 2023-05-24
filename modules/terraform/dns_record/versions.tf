terraform {
  required_version = ">= 0.12.26"
  required_providers {
  #   cloudflare = {
  #     source  = "cloudflare/cloudflare"
  #     version = "~> 2.0"
  #   }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.0"
    }
  }
}
