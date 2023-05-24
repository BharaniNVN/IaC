terraform {
  backend "azurerm" {
    key = "hotfix.orchestration.terraform.tfstate"
  }
}