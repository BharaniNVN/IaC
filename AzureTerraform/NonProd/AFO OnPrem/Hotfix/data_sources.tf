data "terraform_remote_state" "nonprod_shared" {
  backend = "azurerm"
  config = {
    "key"                  = "shared.nonprod.terraform.tfstate"
    "container_name"       = "terraform-states"
    "storage_account_name" = "nonprodmxhhptfsa"
    "resource_group_name"  = "NonprodTerraform-rg"
  }
}

data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "microsoft_graph" {
  display_name = "Microsoft Graph"
}

data "azurerm_client_config" "current" {}
