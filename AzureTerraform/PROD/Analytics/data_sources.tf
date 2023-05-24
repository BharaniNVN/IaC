data "azurerm_client_config" "current" {}

data "terraform_remote_state" "prod_shared" {
  backend = "azurerm"
  config = {
    "key"                  = "shared.prod.terraform.tfstate"
    "container_name"       = "terraform-states"
    "storage_account_name" = "prodmxhhptfsa"
    "resource_group_name"  = "ProdTerraform-rg"
  }
}

data "terraform_remote_state" "shared" {
  backend = "azurerm"
  config = {
    "key"                  = "shared.terraform.tfstate"
    "container_name"       = "terraform-states"
    "storage_account_name" = "prodmxhhptfsa"
    "resource_group_name"  = "ProdTerraform-rg"
  }
}

data "external" "custom_domain_verification" {
  program = ["pwsh", "-command", "az resource show --ids $(az resource list --resource-type Microsoft.Web/sites --query [0].id) --query \"{vid: properties.customDomainVerificationId}\" -o json"]
}
