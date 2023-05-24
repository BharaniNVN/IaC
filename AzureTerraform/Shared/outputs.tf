output "fw" {
  description = "Object of the Azure Firewall in Production subscription used in PROD/DR environments."
  value       = azurerm_firewall.hub_fw
}

output "azure_firewall_public_ip_resource_prod_1" {
  description = "Azure Firewall's public IP resource used for PROD/AFO environment"
  value       = azurerm_public_ip.azure_firewall_prod_1
}

output "azure_firewall_public_ip_resource_prod_2" {
  description = "Azure Firewall's public IP resource used for PROD/OASIS environment."
  value       = azurerm_public_ip.azure_firewall_prod_2
}

output "azure_firewall_public_ip_resource_prod_3" {
  description = "Azure Firewall's public IP resource used for PROD/CodingCenter environment."
  value       = azurerm_public_ip.azure_firewall_prod_3
}

output "azure_firewall_public_ip_resource_prod_4" {
  description = "Azure Firewall's public IP resource used for PROD/Analytics environment."
  value       = azurerm_public_ip.azure_firewall_prod_4
}

output "azure_firewall_public_ip_resource_dr_1" {
  description = "Azure Firewall's public IP resource used for DR/AFO environment."
  value       = azurerm_public_ip.azure_firewall_dr_1
}

output "fw_vnet" {
  description = "Object of the virtual network used for Firewall in Production subscription."
  value       = azurerm_virtual_network.hub_vnet
}

output "azure_firewall_rule_collection_priority_ranges" {
  description = "Map of the priority ranges for Azure Firewall rule collections per each environment."
  value = {
    "prod_shared" = "2000-2999"
    "prod"        = "3000-3999"
    "dr_shared"   = "4000-4999"
    "dr"          = "5000-5999"
    # "shared" = "1101-1999"
  }
}

output "azure_pipelines_agent_subnet_id" {
  description = "ID of the subnet used by Azure Pipelines agents."
  value       = local.pipelines_agent_subnet_resource.id
}

output "sftp_ip_addresses" {
  description = "Map of the SFTP addresses."
  value = {
    "capario" = [var.sftp_capario_ip_address]
    "deyta"   = [var.sftp_deyta_ip_address]
    "hc3"     = [var.sftp_hc3_ip_address]
    "rs"      = [var.sftp_rs_ip_address]
    "tellus"  = [var.sftp_tellus_ip_address]
    "waystar" = [var.sftp_waystar_ip_address]
  }
}
