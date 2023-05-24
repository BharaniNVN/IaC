data "terraform_remote_state" "nonprod_shared" {
  backend = "azurerm"
  config = {
    key                  = "shared.nonprod.terraform.tfstate"
    container_name       = "terraform-states"
    storage_account_name = "nonprodmxhhptfsa"
    resource_group_name  = "NonprodTerraform-rg"
  }
}

data "external" "api_web_app_appsettings" {
  program = ["pwsh", "-command", "$vars=ConvertFrom-Json $([Console]::In.ReadLine()); $result = @{}; (az $vars.apptype config appsettings list --name $vars.app --resource-group $vars.rg --query '[].{name:name,value:value}' -o json | ConvertFrom-Json).Foreach{$result[$($_.name)]=$_.value}; return $result|ConvertTo-Json"]

  query = {
    "rg"      = azurerm_resource_group.this.name
    "app"     = "${local.prefix}-api"
    "apptype" = "webapp"
  }
}

data "external" "app_web_app_appsettings" {
  program = ["pwsh", "-command", "$vars=ConvertFrom-Json $([Console]::In.ReadLine()); $result = @{}; (az $vars.apptype config appsettings list --name $vars.app --resource-group $vars.rg --query '[].{name:name,value:value}' -o json | ConvertFrom-Json).Foreach{$result[$($_.name)]=$_.value}; return $result|ConvertTo-Json"]

  query = {
    "rg"      = azurerm_resource_group.this.name
    "app"     = "${local.prefix}-app"
    "apptype" = "webapp"
  }
}
