terraform {
  backend "azurerm" {
    key = "stage.afoscandocs.terraform.tfstate"
  }
}
