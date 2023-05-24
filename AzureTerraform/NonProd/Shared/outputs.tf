output "vnet" {
  description = "Object of the virtual network used for NonProd environments."
  value       = azurerm_virtual_network.vnet
}

output "office_public_ip_address" {
  description = "Map of office/datacenter name and its public IP address."
  value       = var.office_public_ip_address
}

output "sql_admins_group" {
  description = "Object of the Azure AD group which contains SQL Administrators."
  value       = data.azuread_group.sql_admins
}

output "service_endpoints" {
  description = "List of service endpoints."
  value       = var.service_endpoints
}

output "domain_specifics" {
  description = "Active Directory domain extended information and related services."
  value = merge(
    data.external.domain_information.result,
    {
      "name"          = var.domain_name
      "dns_servers"   = module.domain_controller.dns_servers
      "external_name" = var.external_domain_name
      "update_server" = module.wsus.update_server
    }
  )
}

output "domain_join_credential" {
  description = "Domain join credential for Active Directory domain."
  value       = { "username" = var.domain_join_user, "password" = var.domain_join_pswd }
  sensitive   = true
}

output "vm_operator_credential" {
  description = "Credential information of the service principal with limited rights to Start/Stop virtual machines only."
  value       = { "username" = azuread_application.vm_operator.application_id, "password" = azuread_application_password.vm_operator.value }
  sensitive   = true
}

output "dsc_storage_container" {
  description = "Object of the container in the storage account used to store latest DSC configurations archives for AFO NonProd environments."
  value       = local.dsc_storage_container
}

output "sendgrid_management_api_key" {
  description = "SendGrid management API key for account in NonProd subscription which is used for API key generation in each environment for each product."
  value       = data.azurerm_key_vault_secret.sendgrid_management_api_key.value
  sensitive   = true
}

output "sendgrid_servername" {
  description = "SMTP SendGrid server name."
  value       = data.azurerm_key_vault_secret.sendgrid_server_name.value
}

output "log_analytics" {
  description = "Object of the log analytics workspace used for shared resources in NonProd environments."
  value       = azurerm_log_analytics_workspace.nonprod
}

output "aad_domain_name" {
  description = "Default Azure Active Directory tenant domain."
  value       = data.azuread_domains.aad_domains.domains[0].domain_name
}

output "initial_key_vault_id" {
  description = "ID of the Azure Key Vault in NonProd subscription which contains mostly manually entered information."
  value       = data.azurerm_key_vault.initial.id
}

output "certificates" {
  description = "Map of the available certificates stored in the Azure Key Vault in NonProd subscription along with their latest version urls."
  value = {
    mxhhpdev_com             = data.azurerm_key_vault_secret.mxhhpdev_com.id
    sfsso_brightree_net      = data.azurerm_key_vault_certificate.sfsso_brightree_net.secret_id
    community_matrixcare_com = data.azurerm_key_vault_certificate.community_matrixcare_com.secret_id
    ehomecare_com            = data.azurerm_key_vault_certificate.ehomecare_com.secret_id
    code_signing_matrixcare  = data.azurerm_key_vault_certificate.code_signing_matrixcare.secret_id
  }
}

output "certificates_orders" {
  description = "Map of the certificate names and their order information (e.g. names of the order and resource group)."
  value = {
    mxhhpdev_com = {
      name                = var.mxhhpdev_com_certificate_order_name
      resource_group_name = var.mxhhpdev_com_certificate_order_resource_group_name
    }
  }
}

output "dns_zones" {
  description = "Map of the available DNS zones in NonProd subscription."
  value = {
    mxhhpdev_com = {
      "name"                = var.dns_zone_name
      "resource_group_name" = var.dns_zone_resource_group_name
    }
  }
}

output "key_vault_management_group_id" {
  description = "Object ID of the Azure AD group members of which must be able to access all Azure Key Vaults."
  value       = data.azuread_group.key_vault_management.id
}

output "fw" {
  description = "Object of the Firewall in NonProd subscription."
  value       = azurerm_firewall.nonprod_fw
}

output "azure_firewall_public_ip_resource_1" {
  description = "Azure Firewall's public IP resource in NonProd subscription."
  value       = azurerm_public_ip.fw_pip_1
}

output "fw_rt_id" {
  description = "ID of the route table for NonProd environments."
  value       = azurerm_route_table.fw_rt.id
}

output "agw_subnet_id" {
  description = "ID of the Application Gateway subnet used for access restriction mainly in App Services."
  value       = azurerm_subnet.wafsubnet.id
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
  description = "Map of the NonProd Analytics environments and associated App Service FQDN in them."
  value = {
    "dev"    = format("%s.%s", local.app11, var.external_domain_name)
    "int"    = format("%s.%s", local.app12, var.external_domain_name)
    "stage"  = format("%s.%s", local.app13, var.external_domain_name)
    "hotfix" = format("%s.%s", local.app14, var.external_domain_name)
  }
}

output "azure_firewall_rule_collection_priority_ranges" {
  description = "Map of the priority ranges for Azure Firewall rule collections per each environment."
  value = {
    "dev"    = "5000-5999"
    "int"    = "6000-6999"
    "qa"     = "7000-7999"
    "stage"  = "8000-8999"
    "hotfix" = "9000-9999"
    # "shared" = "1101-1999"
  }
}

output "sftp_ip_addresses" {
  description = "Map of the SFTP addresses."
  value = {
    "capario"       = [var.sftp_capario_ip_address]
    "deyta"         = [var.sftp_deyta_ip_address]
    "hc3"           = [var.sftp_hc3_ip_address]
    "matrixcarehhp" = [var.sftp_matrixcarehhp_ip_address]
    "rs"            = [var.sftp_rs_ip_address]
    "tellus"        = [var.sftp_tellus_ip_address]
    "waystar"       = [var.sftp_waystar_ip_address]
  }
}
