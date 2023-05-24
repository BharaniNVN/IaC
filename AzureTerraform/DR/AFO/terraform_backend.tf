terraform {
  backend "azurerm" {
    key = "afo.dr.terraform.tfstate"
  }
}
