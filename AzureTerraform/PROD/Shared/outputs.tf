output "sendgrid_management_api_key" {
  description = "SendGrid management API key for account in PROD subscription which is used for API key generation in each environment for each product."
  value       = data.azurerm_key_vault_secret.sendgrid_management_api_key.value
  sensitive   = true
}

output "sendgrid_servername" {
  description = "SMTP SendGrid server name."
  value       = data.azurerm_key_vault_secret.sendgrid_server_name.value
}

output "vnet" {
  description = "Object of the virtual network used for PROD environments."
  value       = azurerm_virtual_network.vnet
}

output "log_analytics" {
  description = "Object of the log analytics workspace used for shared resources in PROD environments."
  value       = azurerm_log_analytics_workspace.this
}

output "dsc_storage_container" {
  description = "Object of the container in the storage account used to store latest DSC configurations archives for AFO PROD environment."
  value       = local.dsc_storage_container
}

output "office_public_ip_address" {
  description = "Map of office/datacenter name and its public IP address."
  value       = var.office_public_ip_address
}

output "internal_dns_servers" {
  description = "[DEPRECATED]: List of DNS servers in internal domain."
  value       = module.internal_domain_controller.dns_servers
}

output "dmz_dns_servers" {
  description = "[DEPRECATED]: List of DNS servers in DMZ domain."
  value       = module.dmz_domain_controller.dns_servers
}

output "update_server" {
  description = "[DEPRECATED]: Windows update connection url for clients to obtain updates from WSUS server."
  value       = module.wsus.update_server
}

output "route_table_id" {
  description = "ID of the route table for DR environments."
  value       = azurerm_route_table.prod_rt.id
}

output "aad_domain_name" {
  description = "Default Azure Active Directory tenant domain."
  value       = local.aad_domain_name
}

output "key_vault_management_group_id" {
  description = "Object ID of the Azure AD group members of which must be able to access all Azure Key Vaults."
  value       = data.azuread_group.key_vault_management.id
}

output "sql_admins_group" {
  description = "Object of the Azure AD group which contains SQL Administrators."
  value       = data.azuread_group.sql_admins
}

output "initial_key_vault_id" {
  description = "ID of the Azure Key Vault in PROD subscription which contains mostly manually entered information."
  value       = data.azurerm_key_vault.initial.id
}

output "certificates" {
  description = "Map of the available certificates stored in the Azure Key Vault in PROD subscription along with their latest version urls."
  value = {
    careanyware_com          = data.azurerm_key_vault_certificate.careanyware_com.secret_id
    matrixcarehhp_com        = data.azurerm_key_vault_secret.matrixcarehhp_com.id
    sfsso_brightree_net      = data.azurerm_key_vault_certificate.sfsso_brightree_net.secret_id
    community_matrixcare_com = data.azurerm_key_vault_certificate.community_matrixcare_com.secret_id
    ehomecare_com            = data.azurerm_key_vault_certificate.ehomecare_com.secret_id
  }
}

output "certificates_orders" {
  description = "Map of the certificate names and their order information (e.g. names of the order and resource group)."
  value = {
    matrixcarehhp_com = {
      name                = var.matrixcarehhp_com_certificate_order_name
      resource_group_name = var.matrixcarehhp_com_certificate_order_resource_group_name
    }
  }
}

output "dns_zones" {
  description = "Map of the available DNS zones in PROD subscription."
  value = {
    matrixcarehhp_com = {
      "name"                = var.dns_zone_name
      "resource_group_name" = var.dns_zone_resource_group_name
    }
  }
}

output "key_vault_id" {
  description = "[DEPRECATED]: ID of the shared Azure Key Vault in the PROD subscription."
  value       = azurerm_key_vault.prod_shared_old.id
}

output "agw_subnet_id" {
  description = "ID of the Application Gateway subnet used for access restriction mainly in App Services."
  value       = azurerm_subnet.wafsubnet.id
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

output "vm_operator_credential" {
  description = "Credential information of the service principal with limited rights to Start/Stop virtual machines only."
  value       = { "username" = azuread_application.vm_operator.application_id, "password" = azuread_application_password.vm_operator.value }
  sensitive   = true
}

output "eventhub_policy" {
  description = "Object of the Authorization Rule for an Event Hub Namespace used to send diagnostic information to AlienVault service."
  value       = azurerm_eventhub_namespace_authorization_rule.alienvault
}

output "eventhub_name" {
  description = "Name of the Event Hub used to send diagnostic information to AlienVault service."
  value       = azurerm_eventhub.alienvault.name
}

output "analytics_appservices" {
  description = "Map of the Analytics environment and associated App Service FQDN in PROD subscription."
  value = {
    "prod" = format("%s.%s", local.app04, local.aad_domain_name)
  }
}

output "azure_firewall_rule_collection_priority_ranges" {
  description = "Map of the priority ranges for Azure Firewall rule collections per each environment."
  value       = data.terraform_remote_state.shared.outputs.azure_firewall_rule_collection_priority_ranges
}

output "sftp_ip_addresses" {
  description = "Map of the SFTP addresses."
  value       = data.terraform_remote_state.shared.outputs.sftp_ip_addresses
}
