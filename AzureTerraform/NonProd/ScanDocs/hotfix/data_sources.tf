data "terraform_remote_state" "nonprod_shared" {
  backend = "azurerm"
  config = {
    "key"                  = "shared.nonprod.terraform.tfstate"
    "container_name"       = "terraform-states"
    "storage_account_name" = "nonprodmxhhptfsa"
    "resource_group_name"  = "NonprodTerraform-rg"
  }
}
