data "terraform_remote_state" "nonprod_shared" {
  backend = "azurerm"
  config = {
    "key"                  = "shared.nonprod.terraform.tfstate"
    "container_name"       = "terraform-states"
    "storage_account_name" = "nonprodmxhhptfsa"
    "resource_group_name"  = "NonprodTerraform-rg"
  }
}

data "terraform_remote_state" "oasis_shared" {
  backend = "azurerm"
  config = {
    "key"                  = "shared.oasis.terraform.tfstate"
    "container_name"       = "terraform-states"
    "storage_account_name" = "nonprodmxhhptfsa"
    "resource_group_name"  = "NonprodTerraform-rg"
  }
}

data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "azure_active_directory_graph" {
  display_name = "Windows Azure Active Directory"
}

data "azuread_service_principal" "microsoft_graph" {
  display_name = "Microsoft Graph"
}

data "azurerm_client_config" "current" {}

data "external" "app_service_appsettings" {
  program = ["pwsh", "-command", "$vars=ConvertFrom-Json $([Console]::In.ReadLine()); $result = @{}; (az $vars.apptype config appsettings list --name $vars.app --resource-group $vars.rg --query '[].{name:name,value:value}' -o json | ConvertFrom-Json).Foreach{$result[$($_.name)]=$_.value}; return $result|ConvertTo-Json"]

  query = {
    "rg"      = azurerm_resource_group.this.name
    "app"     = "${local.deprecated_prefix}-as"
    "apptype" = "webapp"
  }
}

data "external" "function_app_appsettings" {
  program = ["pwsh", "-command", "$vars=ConvertFrom-Json $([Console]::In.ReadLine()); $result = @{}; (az $vars.apptype config appsettings list --name $vars.app --resource-group $vars.rg --query '[?name != `AzureWebJobsDashboard` && name != `AzureWebJobsStorage` && name != `FUNCTIONS_EXTENSION_VERSION`].{name:name,value:value}' -o json | ConvertFrom-Json).Foreach{$result[$($_.name)]=$_.value}; return $result|ConvertTo-Json"]

  query = {
    "rg"      = azurerm_resource_group.this.name
    "app"     = "${local.deprecated_prefix}-fct-app"
    "apptype" = "functionapp"
  }
}
