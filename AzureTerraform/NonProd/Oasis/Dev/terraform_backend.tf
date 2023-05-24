terraform {
  backend "azurerm" {
    key = "dev.oasis.terraform.tfstate"
  }
}
