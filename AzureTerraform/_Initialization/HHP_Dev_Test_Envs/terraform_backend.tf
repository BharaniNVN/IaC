terraform {
  backend "azurerm" {
    storage_account_name = "nonprodmxhhptfsa"                        #do not change
    container_name       = "terraform-init"                          #do not change
    key                  = "nonprod.initalization.terraform.tfstate" #do not change
  }
}
