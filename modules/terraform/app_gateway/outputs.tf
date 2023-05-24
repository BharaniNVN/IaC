output "public_ip_id" {
  description = "ID of public IP address for Application Gateway, required for TrafficManager module"
  value       = contains(var.fe_configs, "public") ? azurerm_public_ip.this[0].id : null
}

output "private_ip" {
  description = "Private Front End IP address of the AGW"
  value       = element(concat(compact(azurerm_application_gateway.agw.frontend_ip_configuration[*].private_ip_address), [""]), 0)
}
