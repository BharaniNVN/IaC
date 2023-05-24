terraform {
  backend "azurerm" {
    key = "qa.oasis.terraform.tfstate"
  }
}
