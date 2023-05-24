output "ostype" {
  description = "Type of the OS."
  value       = local.os_type
}

output "first" {
  description = "Name of the first virtual machine."
  value       = try([for _, v in merge(azurerm_windows_virtual_machine.this, azurerm_linux_virtual_machine.this) : v.name][0], "")
}

output "name" {
  description = "List of the virtual machines names."
  value       = local.virtual_machine_name
}

output "id" {
  description = "Map of virtual machine names with their IDs."
  value       = { for k, v in merge(azurerm_windows_virtual_machine.this, azurerm_linux_virtual_machine.this) : k => v.id }

  depends_on = [azurerm_virtual_machine_data_disk_attachment.this]
}

output "identity" {
  description = "Map of virtual machine names with their identities blocks."
  value       = { for k, v in merge(azurerm_windows_virtual_machine.this, azurerm_linux_virtual_machine.this) : k => try(v.identity[0], {}) }

  depends_on = [azurerm_virtual_machine_data_disk_attachment.this]
}

output "availability_set_id" {
  description = "ID of the availability set."
  value       = local.availability_set_id
}

output "ip_address" {
  description = "List of the virtual machines IP addresses."
  value       = [for _, v in azurerm_network_interface.this : v.private_ip_address]
}

output "lb_ip_address" {
  description = "IP address of the internal load balancer."
  value       = try(azurerm_lb.this[0].private_ip_address, null)
}

output "lb_backend_address_pool_id" {
  description = "ID of load balancer backend address pool."
  value       = local.lb_backend_address_pool_id
}

output "name_with_ip_address" {
  description = "Map of the virtual machines names with their IP addresses."
  value       = { for k, v in azurerm_network_interface.this : k => v.private_ip_address }
}

output "boot_diagnostics_storage_blob_endpoint" {
  description = "Boot diagnostic storage URI."
  value       = local.boot_diag_stor_blob_ep
}
