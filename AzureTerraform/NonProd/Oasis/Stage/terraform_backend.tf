terraform {
  backend "azurerm" {
    key = "stage.oasis.terraform.tfstate"
  }
}
