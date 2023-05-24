terraform {
  backend "azurerm" {
    key = "shared.oasis.terraform.tfstate"
  }
}
