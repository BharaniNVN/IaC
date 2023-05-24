terraform {
  backend "azurerm" {
    storage_account_name = "prodmxhhptfsa"                        #do not change
    container_name       = "terraform-init"                       #do not change
    key                  = "prod.initalization.terraform.tfstate" #do not change
  }
}
