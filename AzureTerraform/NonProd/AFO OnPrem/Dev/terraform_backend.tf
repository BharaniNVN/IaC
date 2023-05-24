terraform {
  backend "azurerm" {
    key = "dev.afoonprem.terraform.tfstate"
  }
}
