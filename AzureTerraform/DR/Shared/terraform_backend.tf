terraform {
  backend "azurerm" {
    key = "shared.dr.terraform.tfstate"
  }
}
