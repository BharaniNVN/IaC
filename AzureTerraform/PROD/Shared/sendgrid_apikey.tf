module "sendgrid_apikey" {
  source = "../../../modules/terraform/sendgrid_apikey"

  api_key_name             = format("%s-shared-mail", local.deprecated_prefix)
  key_vault_id             = azurerm_key_vault.prod_shared_old.id
  management_api_key_value = data.azurerm_key_vault_secret.sendgrid_management_api_key.value
  secret_name              = format("%s-shared-mail-apikey", local.deprecated_prefix)
}
