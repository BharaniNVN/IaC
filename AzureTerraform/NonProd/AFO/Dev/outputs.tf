output "sql_shared_ip_port" {
  description = "IP address of the shared SQL server for AFO product in Dev environment."
  value       = module.sql_shared.name_with_ip_address_and_port["${local.prefix}-sqlsaz01"]
}
