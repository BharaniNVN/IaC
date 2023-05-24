terraform {
  backend "azurerm" {
    key = "shared.nonprod.terraform.tfstate"
  }
}
