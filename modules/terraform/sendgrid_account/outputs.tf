output "sendgrid_password" {
  description = "SendGrid account password."
  value       = var.key_vault_resource != null ? azurerm_key_vault_secret.password[0].value : local.password
  sensitive   = true
}

output "sendgrid_server_name" {
  description = "SendGrid server name."
  value       = var.key_vault_resource != null ? azurerm_key_vault_secret.server_name[0].value : jsondecode(azurerm_resource_group_template_deployment.this.output_content)["server_name"]["value"]
}

output "sendgrid_username" {
  description = "SendGrid account username."
  value       = var.key_vault_resource != null ? azurerm_key_vault_secret.username[0].value : jsondecode(azurerm_resource_group_template_deployment.this.output_content)["username"]["value"]
}
