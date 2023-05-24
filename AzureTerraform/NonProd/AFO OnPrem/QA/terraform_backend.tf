terraform {
  backend "azurerm" {
    key = "qa.afoonprem.terraform.tfstate"
  }
}
