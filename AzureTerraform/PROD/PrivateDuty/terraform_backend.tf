terraform {
  backend "azurerm" {
    key = "privateduty.prod.terraform.tfstate"
  }
}
