terraform {
  backend "azurerm" {
    key = "stage.afo.terraform.tfstate"
  }
}
