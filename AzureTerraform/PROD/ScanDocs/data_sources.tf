data "terraform_remote_state" "prod_shared" {
  backend = "azurerm"
  config = {
    "key"                  = "shared.prod.terraform.tfstate"
    "container_name"       = "terraform-states"
    "storage_account_name" = "prodmxhhptfsa"
    "resource_group_name"  = "ProdTerraform-rg"
  }
}
