output "name" {
  description = "The name of the private endpoint."
  value       = azurerm_private_endpoint.this.private_service_connection[0].name

  depends_on = [data.external.clean_reserved_ips]
}

output "private_ip_address" {
  description = "The private IP address associated with the private endpoint."
  value       = azurerm_private_endpoint.this.private_service_connection[0].private_ip_address

  depends_on = [data.external.clean_reserved_ips]
}
