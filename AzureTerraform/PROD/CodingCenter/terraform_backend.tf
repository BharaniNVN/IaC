terraform {
  backend "azurerm" {
    key = "codingcenter.prod.terraform.tfstate"
  }
}
