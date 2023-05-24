output "function_feature_flags_url" {
  description = "The feature flag Api endpoint"
  value       = azurerm_function_app.this.default_hostname
}