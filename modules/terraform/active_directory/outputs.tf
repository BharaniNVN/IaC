output "name" {
  description = "List of the virtual machines names."
  value       = concat(module.virtual_machine_primary.name, module.virtual_machine.name)

  depends_on = [
    azurerm_virtual_machine_extension.dsc
  ]
}

output "fqdn" {
  description = "List of the virtual machines fully qualified domain names."
  value       = formatlist("%s.%s", concat(module.virtual_machine_primary.name, module.virtual_machine.name), var.domain_name)
}

output "identity" {
  description = "Map of virtual machine names with their identities blocks."
  value       = merge(module.virtual_machine_primary.identity, module.virtual_machine.identity)
}

output "ip_address" {
  description = "List of the virtual machines IP addresses."
  value       = concat(module.virtual_machine_primary.ip_address, module.virtual_machine.ip_address)
}

output "lb_ip_address" {
  description = "IP address of the internal load balancer."
  value       = var.enable_internal_loadbalancer ? var.deploy_domain ? module.virtual_machine_primary.lb_ip_address : module.virtual_machine.lb_ip_address : null
}

output "name_with_ip_address" {
  description = "Map of the virtual machines names with their IP addresses."
  value       = merge(module.virtual_machine_primary.name_with_ip_address, module.virtual_machine.name_with_ip_address)
}

output "fqdn_with_ip_address" {
  description = "Map of the virtual machines fully qualified domain names with their IP addresses."
  value = merge(
    { for k, v in module.virtual_machine_primary.name_with_ip_address : format("%s.%s", k, var.domain_name) => v },
    { for k, v in module.virtual_machine.name_with_ip_address : format("%s.%s", k, var.domain_name) => v },
  )
}

output "dns_servers" {
  description = "Virtual machines IP addresses combined with their DNS servers to create a DNS list for other virtual machines in the same domain."
  value = distinct(
    concat(
      module.virtual_machine_primary.ip_address,
      module.virtual_machine.ip_address,
      var.dns_servers,
    )
  )

  depends_on = [
    azurerm_virtual_machine_extension.dsc
  ]
}
