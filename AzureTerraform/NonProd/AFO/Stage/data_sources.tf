data "terraform_remote_state" "nonprod_shared" {
  backend = "azurerm"
  config = {
    "key"                  = "shared.nonprod.terraform.tfstate"
    "container_name"       = "terraform-states"
    "storage_account_name" = "nonprodmxhhptfsa"
    "resource_group_name"  = "NonprodTerraform-rg"
  }
}

data "terraform_remote_state" "shared_afo" {
  backend = "azurerm"
  config = {
    "key"                  = "shared.afo.terraform.tfstate"
    "container_name"       = "terraform-states"
    "storage_account_name" = "nonprodmxhhptfsa"
    "resource_group_name"  = "NonprodTerraform-rg"
  }
}

data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "azure_devops_spn" {
  display_name = var.azure_devops_spn_displayname
}

data "azuread_service_principal" "microsoft_graph" {
  display_name = "Microsoft Graph"
}

data "azurerm_client_config" "current" {}

data "external" "azure_devops_agent_ip" {
  program = ["pwsh", "-command", "& { $vars=ConvertFrom-Json $([Console]::In.ReadLine()); $ip = $(Invoke-RestMethod https://checkip.amazonaws.com -Headers @{\"User-Agent\"=\"curl/7.58.0\"} -TimeoutSec 30) -replace '[^0-9.]'; $sa = az storage account list --query \"[?name=='$($vars.name)']\" -o json --only-show-errors 2>&1 | ConvertFrom-Json; if ($LASTEXITCODE) { throw $sa } elseif ($error.Count) { exit 1 }; if ($sa.Count -eq 1 -and (az storage share exists --account-name $sa.name --name non-existent --only-show-errors 2>&1) -match 'AuthorizationFailure') {az storage account network-rule add -g $sa.resourceGroup --account-name $sa.name --ip-address $ip -o none; while ((az storage share exists --account-name $sa.name --name non-existent --only-show-errors 2>&1) -match 'AuthorizationFailure') { Start-Sleep -Seconds 5; }}; return '{}' }"]

  query = {
    "name" = azurerm_storage_account.this.name
  }
}

data "azurerm_app_service_certificate_order" "mxhhpdev_com" {
  name                = data.terraform_remote_state.nonprod_shared.outputs.certificates_orders["mxhhpdev_com"].name
  resource_group_name = data.terraform_remote_state.nonprod_shared.outputs.certificates_orders["mxhhpdev_com"].resource_group_name
}
