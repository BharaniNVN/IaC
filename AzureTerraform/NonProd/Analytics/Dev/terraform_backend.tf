terraform {
  backend "azurerm" {
    key = "dev.analytics.terraform.tfstate"
  }
}
