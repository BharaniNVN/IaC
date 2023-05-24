terraform {
  backend "azurerm" {
    key = "qa.privateduty.terraform.tfstate"
  }
}
