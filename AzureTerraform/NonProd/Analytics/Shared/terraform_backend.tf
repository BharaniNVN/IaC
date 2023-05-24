terraform {
  backend "azurerm" {
    key = "shared.analytics.terraform.tfstate"
  }
}
