terraform {
  backend "azurerm" {
    key = "int.afoscandocs.terraform.tfstate"
  }
}
