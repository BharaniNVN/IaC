terraform {
  backend "azurerm" {
    key = "shared.privateduty.terraform.tfstate"
  }
}
