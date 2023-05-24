data "azuread_application_published_app_ids" "well_known" {}

data "azuread_group" "sql_admins" {
  display_name = "AzureSqlAdmins"
}

data "azuread_domains" "aad_domains" {
  only_default = true
}

data "azuread_group" "key_vault_management" {
  display_name = "KeyVaultManagement"
}

data "azuread_service_principal" "microsoft_graph" {
  display_name = "Microsoft Graph"
}

data "azurerm_app_service_certificate_order" "mxhhpdev_com" {
  name                = var.mxhhpdev_com_certificate_order_name
  resource_group_name = var.mxhhpdev_com_certificate_order_resource_group_name
}

data "azurerm_client_config" "current" {}

data "azurerm_key_vault" "initial" {
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group_name
}

data "azurerm_key_vault_secret" "mxhhpdev_com" {
  name         = data.azurerm_app_service_certificate_order.mxhhpdev_com.certificates[0].key_vault_secret_name
  key_vault_id = data.azurerm_app_service_certificate_order.mxhhpdev_com.certificates[0].key_vault_id
}

data "azurerm_key_vault_certificate" "code_signing_matrixcare" {
  name         = var.code_signing_matrixcare_certificate_secret_name
  key_vault_id = data.azurerm_key_vault.initial.id
}

data "azurerm_key_vault_certificate" "sfsso_brightree_net" {
  name         = var.sfsso_brightree_net_certificate_secret_name
  key_vault_id = data.azurerm_key_vault.initial.id
}

data "azurerm_key_vault_certificate" "community_matrixcare_com" {
  name         = var.community_matrixcare_com_certificate_secret_name
  key_vault_id = data.azurerm_key_vault.initial.id
}

data "azurerm_key_vault_certificate" "ehomecare_com" {
  name         = var.ehomecare_com_certificate_secret_name
  key_vault_id = data.azurerm_key_vault.initial.id
}

data "azurerm_key_vault_secret" "pipelines_agent_subnet_resource" {
  name         = var.pipelines_agent_subnet_resource_secret_name
  key_vault_id = data.azurerm_key_vault.initial.id
}

data "azurerm_key_vault_secret" "sendgrid_management_api_key" {
  name         = var.sendgrid_management_api_key_secret_name
  key_vault_id = data.azurerm_key_vault.initial.id
}

data "azurerm_key_vault_secret" "sendgrid_server_name" {
  name         = var.sendgrid_server_name_secret_name
  key_vault_id = data.azurerm_key_vault.initial.id
}

data "external" "domain_information" {
  program = ["pwsh", "-command", "& {$vars=ConvertFrom-Json $([Console]::In.ReadLine()); $result = az vm run-command invoke --command-id RunPowerShellScript --name $vars.vm -g $vars.rg --scripts 'Import-Module ActiveDirectory; Get-ADDomain | Select-Object -Property dnsroot,@{l=\\\"domainsid\\\";e={$_.DomainSID.Value}},forest,netbiosname,objectguid | ConvertTo-Json -Compress' --query value -o json --only-show-errors 2>&1; if ($LASTEXITCODE) {throw $result} elseif ($error.Count) { exit 1 } else { $stderr = ($result|ConvertFrom-Json).Where{$_.code -match 'StdErr'}.message; $stdout=($result|ConvertFrom-Json).Where{$_.code -match 'StdOut'}.message; if ($stderr) {throw $stderr} else {return $stdout} } }"]

  query = {
    "rg" = azurerm_resource_group.shared_infra.name
    "vm" = module.domain_controller.name[0]
  }

  depends_on = [
    module.domain_controller
  ]
}

data "dns_a_record_set" "dns_records_external" {
  for_each = toset([for each in var.dns_records_external : format("%s.%s", each.name, each.zone)])

  host = each.value
}

data "azurerm_policy_definition" "builtin" {
  for_each = var.builtin_azure_policy_definition_names

  name = each.value
}
