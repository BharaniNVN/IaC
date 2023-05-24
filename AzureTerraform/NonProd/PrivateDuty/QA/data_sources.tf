data "azurerm_client_config" "current" {}

data "terraform_remote_state" "nonprod_shared" {
  backend = "azurerm"
  config = {
    key                  = "shared.nonprod.terraform.tfstate"
    container_name       = "terraform-states"
    storage_account_name = "nonprodmxhhptfsa"
    resource_group_name  = "NonprodTerraform-rg"
  }
}

data "terraform_remote_state" "privateduty_shared" {
  backend = "azurerm"
  config = {
    key                  = "shared.privateduty.terraform.tfstate"
    container_name       = "terraform-states"
    storage_account_name = "nonprodmxhhptfsa"
    resource_group_name  = "NonprodTerraform-rg"
  }
}

data "azuread_service_principal" "azure_devops_spn" {
  display_name = var.azure_devops_spn_displayname
}

data "azuread_groups" "this" {
  display_names = var.aad_groups
}

data "azuread_group" "env_access_group" {
  display_name = var.aad_env_access_group
}

data "azurerm_key_vault_certificate" "code_signing_matrixcare" {
  name         = split("/", data.terraform_remote_state.nonprod_shared.outputs.certificates["code_signing_matrixcare"])[4]
  key_vault_id = data.terraform_remote_state.nonprod_shared.outputs.initial_key_vault_id
}

data "azurerm_app_service_certificate_order" "mxhhpdev_com" {
  name                = data.terraform_remote_state.nonprod_shared.outputs.certificates_orders["mxhhpdev_com"].name
  resource_group_name = data.terraform_remote_state.nonprod_shared.outputs.certificates_orders["mxhhpdev_com"].resource_group_name
}
