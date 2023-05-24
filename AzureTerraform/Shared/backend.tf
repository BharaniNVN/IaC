terraform {
  backend "azurerm" {
    key = "shared.terraform.tfstate"
  }
}
