output "adf_principal_id" {
  description = "The ID of the Principal (Client) in Azure Active Directory associated with the Azure Data Factory."
  value       = azurerm_data_factory.this.identity[0].principal_id
}

output "sql_server_internal_ip" {
  description = "IP address of the SQL server."
  value       = lookup(module.sql.name_with_ip_address, "intana-sql")
}

output "azure_sql_fqdn" {
  description = "The fully qualified domain name of the Azure SQL Server."
  value       = azurerm_sql_server.analytics.fully_qualified_domain_name
}

output "db_name" {
  description = "The name of the SQL database."
  value       = azurerm_sql_database.analytics.name
}

output "irkey" {
  description = "The primary authentication key for Data Factory Self-hosted Integration Runtime."
  value       = azurerm_template_deployment.ir.outputs["irkey"]
  sensitive   = true
}
