output "decryption_key" {
  description = "Decryption key value."
  value       = azurerm_key_vault_secret.decryption_key.value
}

output "decryption_method" {
  description = "Decryption method value."
  value       = azurerm_key_vault_secret.decryption_method.value
}

output "validation_key" {
  description = "Validation key value."
  value       = azurerm_key_vault_secret.validation_key.value
}

output "validation_method" {
  description = "Validation method value."
  value       = azurerm_key_vault_secret.validation_method.value
}