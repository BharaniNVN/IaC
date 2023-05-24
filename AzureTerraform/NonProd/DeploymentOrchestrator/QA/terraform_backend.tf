terraform {
  backend "azurerm" {
    key = "qa.orchestration.terraform.tfstate"
  }
}