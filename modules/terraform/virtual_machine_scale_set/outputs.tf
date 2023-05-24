output "os_type" {
  description = "Type of the OS."
  value       = local.os_type
}

output "first" {
  description = "Name of the first virtual machine scale set."
  value       = try([for _, v in merge(azurerm_windows_virtual_machine_scale_set.this, azurerm_linux_virtual_machine_scale_set.this) : v.name][0], "")
}

output "name" {
  description = "List of the virtual machines scale set names."
  value       = local.virtual_machine_scale_set_name
}

output "id" {
  description = "Map of virtual machine scale set names with their IDs."
  value       = { for k, v in merge(azurerm_windows_virtual_machine_scale_set.this, azurerm_linux_virtual_machine_scale_set.this) : k => v.id }
}

output "lb_ip_address" {
  description = "IP address of the internal load balancer."
  value       = try(azurerm_lb.this[0].private_ip_address, null)
}

output "lb_backend_address_pool_id" {
  description = "ID of load balancer backend address pool."
  value       = local.lb_backend_address_pool_id
}

output "boot_diagnostics_storage_blob_endpoint" {
  description = "Boot diagnostic storage URI."
  value       = local.boot_diag_stor_blob_ep
}
