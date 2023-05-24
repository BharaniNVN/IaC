output "api_key" {
  description = "The API Key secret."
  value       = length(azurerm_application_insights_api_key.this) == 1 ? [for _, v in azurerm_application_insights_api_key.this : v.api_key][0] : null
  sensitive   = true
}

output "api_keys" {
  description = "The API Key secrets."
  value       = { for _, v in azurerm_application_insights_api_key.this : v.name => v.api_key }
  sensitive   = true
}

output "app_id" {
  description = "The App ID associated with this Application Insights component."
  value       = azurerm_application_insights.this.app_id
}

output "connection_string" {
  description = "The Connection String for this Application Insights component."
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}

output "id" {
  description = "The ID of the Application Insights component."
  value       = azurerm_application_insights.this.id
}

output "instrumentation_key" {
  description = "The Instrumentation Key for this Application Insights component."
  value       = azurerm_application_insights.this.instrumentation_key
  sensitive   = true
}

output "location" {
  description = "Azure region where Application Insights component was deployed."
  value       = azurerm_application_insights.this.location
}

output "name" {
  description = "The name of the Application Insights component."
  value       = azurerm_application_insights.this.name
}
