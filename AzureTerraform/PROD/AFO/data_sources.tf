data "terraform_remote_state" "prod_shared" {
  backend = "azurerm"
  config = {
    "key"                  = "shared.prod.terraform.tfstate"
    "container_name"       = "terraform-states"
    "storage_account_name" = "prodmxhhptfsa"
    "resource_group_name"  = "ProdTerraform-rg"
  }
}

# data "terraform_remote_state" "shared" {
#   backend = "azurerm"
#   config = {
#     "key"                  = "shared.terraform.tfstate"
#     "container_name"       = "terraform-states"
#     "storage_account_name" = "prodmxhhptfsa"
#     "resource_group_name"  = "ProdTerraform-rg"
#   }
# }

data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "azure_devops_spn" {
  display_name = var.azure_devops_spn_displayname
}

data "azuread_service_principal" "microsoft_graph" {
  display_name = "Microsoft Graph"
}

data "azurerm_client_config" "current" {}

data "azurerm_key_vault_certificate" "careanyware_com" {
  name         = split("/", local.cert_careanyware)[4]
  key_vault_id = data.terraform_remote_state.prod_shared.outputs.initial_key_vault_id
}
