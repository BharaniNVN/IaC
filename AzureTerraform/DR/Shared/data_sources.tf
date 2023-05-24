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

data "azuread_domains" "aad_domains" {
  only_default = true
}

data "azurerm_key_vault" "initial" {
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group_name
}

data "azurerm_key_vault_certificate" "careanyware_com" {
  name         = var.careanyware_certificate_secret_name
  key_vault_id = data.azurerm_key_vault.initial.id
}

data "azurerm_key_vault_certificate" "community_matrixcare_com" {
  name         = var.community_matrixcare_com_certificate_secret_name
  key_vault_id = data.azurerm_key_vault.initial.id
}

data "external" "internal_domain_information" {
  program = ["pwsh", "-command", "& {$vars=ConvertFrom-Json $([Console]::In.ReadLine()); $result = az vm run-command invoke --command-id RunPowerShellScript --name $vars.vm -g $vars.rg --scripts 'Import-Module ActiveDirectory; Get-ADDomain | Select-Object -Property dnsroot,@{l=\\\"domainsid\\\";e={$_.DomainSID.Value}},forest,netbiosname,objectguid | ConvertTo-Json -Compress' --query value -o json --only-show-errors 2>&1; if ($LASTEXITCODE) {throw $result} elseif ($error.Count) { exit 1 } else { $stderr = ($result|ConvertFrom-Json).Where{$_.code -match 'StdErr'}.message; $stdout=($result|ConvertFrom-Json).Where{$_.code -match 'StdOut'}.message; if ($stderr) {throw $stderr} else {return $stdout} } }"]

  query = {
    "rg" = azurerm_resource_group.shared_internal.name
    "vm" = module.internal_domain_controller.name[0]
  }

  depends_on = [
    module.internal_domain_controller
  ]
}

data "external" "dmz_domain_information" {
  program = ["pwsh", "-command", "& {$vars=ConvertFrom-Json $([Console]::In.ReadLine()); $result = az vm run-command invoke --command-id RunPowerShellScript --name $vars.vm -g $vars.rg --scripts 'Import-Module ActiveDirectory; Get-ADDomain | Select-Object -Property dnsroot,@{l=\\\"domainsid\\\";e={$_.DomainSID.Value}},forest,netbiosname,objectguid | ConvertTo-Json -Compress' --query value -o json --only-show-errors 2>&1; if ($LASTEXITCODE) {throw $result} elseif ($error.Count) { exit 1 } else { $stderr = ($result|ConvertFrom-Json).Where{$_.code -match 'StdErr'}.message; $stdout=($result|ConvertFrom-Json).Where{$_.code -match 'StdOut'}.message; if ($stderr) {throw $stderr} else {return $stdout} } }"]

  query = {
    "rg" = azurerm_resource_group.shared_dmz.name
    "vm" = module.dmz_domain_controller.name[0]
  }

  depends_on = [
    module.dmz_domain_controller
  ]
}
