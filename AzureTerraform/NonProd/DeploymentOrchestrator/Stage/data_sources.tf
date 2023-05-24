data "terraform_remote_state" "orchestration_shared" {
  backend = "azurerm"
  config = {
    "key"                  = "shared.orchestration.terraform.tfstate"
    "container_name"       = "terraform-states"
    "storage_account_name" = "nonprodmxhhptfsa"
    "resource_group_name"  = "NonprodTerraform-rg"
  }
}