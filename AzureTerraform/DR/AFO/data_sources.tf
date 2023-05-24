data "azurerm_client_config" "current" {}

data "terraform_remote_state" "dr_shared" {
  backend = "azurerm"
  config = {
    "key"                  = "shared.dr.terraform.tfstate"
    "container_name"       = "terraform-states"
    "storage_account_name" = "prodmxhhptfsa"
    "resource_group_name"  = "ProdTerraform-rg"
  }
}

data "terraform_remote_state" "prod_afo" {
  backend = "azurerm"
  config = {
    "key"                  = "afo.prod.terraform.tfstate"
    "container_name"       = "terraform-states"
    "storage_account_name" = "prodmxhhptfsa"
    "resource_group_name"  = "ProdTerraform-rg"
  }
}

data "terraform_remote_state" "prod_shared" {
  backend = "azurerm"
  config = {
    "key"                  = "shared.prod.terraform.tfstate"
    "container_name"       = "terraform-states"
    "storage_account_name" = "prodmxhhptfsa"
    "resource_group_name"  = "ProdTerraform-rg"
  }
}

data "external" "azure_devops_agent_ip" {
  program = ["pwsh", "-file", "${path.module}/scripts/Add-StorageFirewallRule.ps1"]

  query = {
    "name"        = azurerm_storage_account.this.name
    "retry_count" = 5
  }
}

data "azuread_service_principal" "azure_devops_spn" {
  display_name = var.azure_devops_spn_displayname
}

data "azurerm_key_vault_certificate" "careanyware_com" {
  name         = split("/", local.cert_careanyware)[4]
  key_vault_id = data.terraform_remote_state.prod_shared.outputs.initial_key_vault_id
}

data "azurerm_key_vault_secret" "all_managed" {
  for_each = local.prod_secrets_all_managed

  name         = each.value
  key_vault_id = data.terraform_remote_state.prod_afo.outputs.keyvaults_ids["all_managed"]
}
