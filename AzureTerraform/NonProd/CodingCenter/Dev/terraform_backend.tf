terraform {
  backend "azurerm" {
    key = "dev.codingcenter.terraform.tfstate"
  }
}
