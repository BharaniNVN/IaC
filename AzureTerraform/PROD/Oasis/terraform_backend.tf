terraform {
  backend "azurerm" {
    key = "oasis.prod.terraform.tfstate"
  }
}
