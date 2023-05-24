output "app_service_plan_id" {
  description = "ID of the App Service Plan."
  value       = azurerm_service_plan.this.id
}

output "app_service_subnet" {
  description = "Object of subnet used for App Service virtual network integration."
  value       = azurerm_subnet.this
}

output "key_vault_id" {
  description = "ID of the Azure Key Vault for CodingCenter product in NonProd subscription."
  value       = azurerm_key_vault.codingcenter_shared.id
}
