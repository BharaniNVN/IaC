terraform {
  backend "azurerm" {
    key = "shared.codingcenter.terraform.tfstate"
  }
}
