terraform {
  backend "azurerm" {
    key = "stage.analytics.terraform.tfstate"
  }
}
