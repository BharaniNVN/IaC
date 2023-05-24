output "key_vault_secret_name" {
  description = "Secret name in Azure Key Vault where SendGrid API key value is stored."
  value       = azurerm_key_vault_secret.this.name
}

output "sendgrid_api_key_value" {
  description = "SendGrid API key value."
  value       = azurerm_key_vault_secret.this.value
  sensitive   = true
}

output "sendgrid_api_key_username" {
  description = "SendGrid API key username."
  value       = var.api_key_username
}
