# tflint-ignore: terraform_naming_convention
output "ARM_ACCESS_KEY" {
  description = "The Access Key used to access the Blob Storage Account."
  value       = azurerm_storage_account.this.primary_access_key
}

# tflint-ignore: terraform_naming_convention
output "ARM_CLIENT_ID" {
  description = "The Client ID of the Service Principal."
  value       = azuread_application.terraform.application_id
}

# tflint-ignore: terraform_naming_convention
output "ARM_SUBSCRIPTION_ID" {
  description = "The Subscription ID in which the Storage Account exists."
  value       = data.azurerm_subscription.primary.subscription_id
}

# tflint-ignore: terraform_naming_convention
output "ARM_TENANT_ID" {
  description = "The Tenant ID in which the Subscription exists."
  value       = data.azurerm_subscription.primary.tenant_id
}

# tflint-ignore: terraform_naming_convention
output "TF_STORAGE_ACCOUNT" {
  description = "The Name of the Storage Account used to store terraform states."
  value       = azurerm_storage_account.this.name
}

# tflint-ignore: terraform_naming_convention
output "TF_STORAGE_CONTAINER" {
  description = "The Name of the Storage Container within the Storage Account used to store terraform states."
  value       = azurerm_storage_container.states.name
}
