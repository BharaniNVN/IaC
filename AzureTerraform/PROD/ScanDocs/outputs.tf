output "file_endpoint_ip" {
  description = "Storage account private endpoint IP address of File share"
  value       = azurerm_private_endpoint.file.private_service_connection[0].private_ip_address
}

output "blob_endpoint_ip" {
  description = "Storage account private endpoint IP address of BLOB"
  value       = azurerm_private_endpoint.blob.private_service_connection[0].private_ip_address
}
