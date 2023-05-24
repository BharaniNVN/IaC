data "azurerm_client_config" "current" {}

data "terraform_remote_state" "nonprod_shared" {
  backend = "azurerm"
  config = {
    "key"                  = "shared.nonprod.terraform.tfstate"
    "container_name"       = "terraform-states"
    "storage_account_name" = "nonprodmxhhptfsa"
    "resource_group_name"  = "NonprodTerraform-rg"
  }
}

data "terraform_remote_state" "analytics_shared" {
  backend = "azurerm"
  config = {
    "key"                  = "shared.analytics.terraform.tfstate"
    "container_name"       = "terraform-states"
    "storage_account_name" = "nonprodmxhhptfsa"
    "resource_group_name"  = "NonprodTerraform-rg"
  }
}

data "external" "custom_domain_verification" {
  program = ["pwsh", "-command", "az resource show --ids $(az resource list --resource-type Microsoft.Web/sites --query [0].id) --query \"{vid: properties.customDomainVerificationId}\" -o json"]
}
