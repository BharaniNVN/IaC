terraform {
  backend "azurerm" {
    key = "shared.prod.terraform.tfstate"
  }
}
