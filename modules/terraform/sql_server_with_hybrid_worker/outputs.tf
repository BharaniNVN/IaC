output "name" {
  description = "List of the virtual machines names."
  value       = module.virtual_machine.name
}

output "fqdn" {
  description = "List of the virtual machines fully qualified domain names."
  value       = formatlist("%s.%s", module.virtual_machine.name, var.domain_name)
}

output "identity" {
  description = "Map of virtual machine names with their identities blocks."
  value       = module.virtual_machine.identity
}

output "ip_address" {
  description = "List of the virtual machines IP addresses."
  value       = module.virtual_machine.ip_address
}

output "lb_ip_address" {
  description = "IP address of the internal load balancer."
  value       = module.virtual_machine.lb_ip_address
}

output "name_with_ip_address" {
  description = "Map of the virtual machines names with their IP addresses."
  value       = module.virtual_machine.name_with_ip_address
}

output "name_with_port" {
  description = "List of the virtual machines names with their port."
  value       = formatlist("%s,%s", module.virtual_machine.name, var.sql_port)
}

output "fqdn_with_ip_address" {
  description = "Map of the virtual machines fully qualified domain names with their IP addresses."
  value       = { for k, v in module.virtual_machine.name_with_ip_address : format("%s.%s", k, var.domain_name) => v }
}

output "name_with_fqdn_and_port" {
  description = "Map of the virtual machines names with their fully qualified domain names and ports."
  value       = { for k in module.virtual_machine.name : k => format("%s.%s,%s", k, var.domain_name, var.sql_port) }

  depends_on = [
    azurerm_virtual_machine_extension.dsc,
  ]
}

output "name_with_ip_address_and_port" {
  description = "Map of the virtual machines names with their IP addresses."
  value       = { for k, v in module.virtual_machine.name_with_ip_address : k => format("%s,%s", v, var.sql_port) }
}
