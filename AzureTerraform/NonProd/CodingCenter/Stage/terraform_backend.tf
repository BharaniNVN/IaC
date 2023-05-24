terraform {
  backend "azurerm" {
    key = "stage.codingcenter.terraform.tfstate"
  }
}
