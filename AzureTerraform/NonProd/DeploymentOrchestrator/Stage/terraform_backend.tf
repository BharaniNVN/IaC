terraform {
  backend "azurerm" {
    key = "stage.orchestration.terraform.tfstate"
  }
}