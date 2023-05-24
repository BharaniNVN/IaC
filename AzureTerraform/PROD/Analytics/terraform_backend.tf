terraform {
  backend "azurerm" {
    key = "analytics.prod.terraform.tfstate"
  }
}
