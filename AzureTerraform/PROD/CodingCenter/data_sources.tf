data "terraform_remote_state" "prod_shared" {
  backend = "azurerm"
  config = {
    key                  = "shared.prod.terraform.tfstate"
    container_name       = "terraform-states"
    storage_account_name = "prodmxhhptfsa"
    resource_group_name  = "ProdTerraform-rg"
  }
}

data "terraform_remote_state" "prod_oasis" {
  backend = "azurerm"
  config = {
    "key"                  = "oasis.prod.terraform.tfstate"
    "container_name"       = "terraform-states"
    "storage_account_name" = "prodmxhhptfsa"
    "resource_group_name"  = "ProdTerraform-rg"
  }
}

data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "microsoft_graph" {
  display_name = "Microsoft Graph"
}

data "azurerm_client_config" "current" {}

data "external" "app_service_appsettings" {
  program = ["pwsh", "-command", "$vars=ConvertFrom-Json $([Console]::In.ReadLine()); $result = @{}; (az $vars.apptype config appsettings list --name $vars.app --resource-group $vars.rg --query '[].{name:name,value:value}' -o json | ConvertFrom-Json).Foreach{$result[$($_.name)]=$_.value}; return $result|ConvertTo-Json"]

  query = {
    rg      = azurerm_resource_group.this.name
    app     = "${var.deprecated_application_prefix}-as"
    apptype = "webapp"
  }
}
