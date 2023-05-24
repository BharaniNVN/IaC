terraform {
  backend "azurerm" {
    key = "shared.orchestration.terraform.tfstate"
  }
}
