terraform {
  backend "azurerm" {
    key = "afo.prod.terraform.tfstate"
  }
}
