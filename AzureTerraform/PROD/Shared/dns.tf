module "dns_record_sftp" {
  source = "../../../modules/terraform/dns_record"

  azurerm_dns_zone_name       = var.dns_zone_name
  azurerm_resource_group_name = var.dns_zone_resource_group_name
  names                       = ["sftp"]
  targets                     = [data.terraform_remote_state.shared.outputs.azure_firewall_public_ip_resource_prod_1.fqdn]
  type                        = "CNAME"

  azurerm_tags = local.tags
}
