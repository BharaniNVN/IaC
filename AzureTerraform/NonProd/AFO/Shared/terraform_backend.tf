terraform {
  backend "azurerm" {
    key = "shared.afo.terraform.tfstate"
  }
}
