terraform {
  backend "azurerm" {
    storage_account_name = "analyticsmxhhptfsa"                           #do not change
    container_name       = "terraform-init"                               #do not change
    key                  = "analyticspbi.initalization.terraform.tfstate" #do not change
  }
}
