terraform {
  backend "azurerm" {
    key = "dev.orchestration.terraform.tfstate"
  }
}