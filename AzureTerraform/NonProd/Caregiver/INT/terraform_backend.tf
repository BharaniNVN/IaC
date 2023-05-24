terraform {
  backend "azurerm" {
    key = "int.crml.terraform.tfstate"
  }
}
