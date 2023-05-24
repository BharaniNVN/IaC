output "name" {
  description = "List of the virtual machines names."
  value       = module.virtual_machine.name
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
