terraform {
  backend "azurerm" {
    key = "afoscandocs.prod.terraform.tfstate"
  }
}
