output "vnet" {
  description = "Object of the virtual network used for DR environments."
  value       = azurerm_virtual_network.vnet
}

output "log_analytics" {
  description = "Object of the log analytics workspace used for shared resources in DR environments."
  value       = azurerm_log_analytics_workspace.this
}

output "dsc_storage_container" {
  description = "Object of the container in the storage account used to store latest DSC configurations archives for AFO DR environment."
  value       = local.dsc_storage_container
}

output "initial_key_vault_id" {
  description = "ID of the Azure Key Vault in PROD subscription which contains mostly manually entered information."
  value       = data.azurerm_key_vault.initial.id
}

output "certificates" {
  description = "Map of the available certificates stored in the Azure Key Vault in PROD subscription along with their latest version urls."
  value = {
    careanyware_com          = data.azurerm_key_vault_certificate.careanyware_com.secret_id
    community_matrixcare_com = data.azurerm_key_vault_certificate.community_matrixcare_com.secret_id
  }
}

output "internal_domain_join_credential" {
  description = "Domain join credential for Active Directory internal domain."
  value       = { "username" = var.cawprod_join_user, "password" = var.cawprod_join_pswd }
  sensitive   = true
}

output "dmz_domain_join_credential" {
  description = "Domain join credential for Active Directory DMZ domain."
  value       = { "username" = var.cawdmz_join_user, "password" = var.cawdmz_join_pswd }
  sensitive   = true
}

output "internal_domain_specifics" {
  description = "Active Directory internal domain extended information and related services."
  value = merge(
    data.external.internal_domain_information.result,
    {
      "name"          = var.internal_domain
      "dns_servers"   = module.internal_domain_controller.dns_servers
      "update_server" = module.wsus.update_server
    }
  )
}

output "dmz_domain_specifics" {
  description = "Active Directory DMZ domain extended information and related services."
  value = merge(
    data.external.dmz_domain_information.result,
    {
      "name"          = var.dmz_domain
      "dns_servers"   = module.dmz_domain_controller.dns_servers
      "external_name" = var.external_domain_name
      "update_server" = module.wsus.update_server
    }
  )
}

output "route_table_id" {
  description = "ID of the route table for DR environments."
  value       = azurerm_route_table.dr_rt.id
}

output "aad_domain_name" {
  description = "Default Azure Active Directory tenant domain."
  value       = local.aad_domain_name
}

output "azure_firewall_resource" {
  description = "Object of the Azure Firewall in Production subscription used in PROD/DR environments."
  value       = data.terraform_remote_state.shared.outputs.fw
}

output "azure_firewall_rule_collection_priority_ranges" {
  description = "Map of the priority ranges for Azure Firewall rule collections per each environment."
  value       = data.terraform_remote_state.shared.outputs.azure_firewall_rule_collection_priority_ranges
}

output "sftp_ip_addresses" {
  description = "Map of the SFTP addresses."
  value       = data.terraform_remote_state.shared.outputs.sftp_ip_addresses
}

output "onprem_db_backup_storage_account_ids" {
  description = <<EOF
                Map of storage accounts' names and ids meant for on-premise DB backups.
                Used in DR-AFO pipelines as a reference to setup RBAC permissions.
                DB VMs created during DR procedure need to have their managed identities
                assigned Storage Blob Data Reader, so drafo-sql-db-restore runbook can
                actually access the backup files.
                EOF
  value       = { for storage in azurerm_storage_account.onprem_db_backups : storage.name => storage.id }
}