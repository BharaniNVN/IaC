terraform {
  backend "azurerm" {
    key = "int.analytics.terraform.tfstate"
  }
}
