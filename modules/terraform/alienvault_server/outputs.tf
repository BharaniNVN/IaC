output "name" {
  description = "List of the virtual machines names."
  value       = [azurerm_virtual_machine.this.name]
}

output "identity" {
  description = "Virtual machine identities."
  value       = try(azurerm_virtual_machine.this.identity[0], {})
}

output "ip_address" {
  description = "List of the virtual machines IP addresses."
  value       = [azurerm_network_interface.this.private_ip_address]
}
