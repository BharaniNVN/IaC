terraform {
  backend "azurerm" {
    key = "prod.orchestration.terraform.tfstate"
  }
}