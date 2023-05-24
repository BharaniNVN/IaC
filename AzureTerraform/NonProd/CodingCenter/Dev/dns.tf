module "dns_record" {
  source = "../../../../modules/terraform/dns_record"

  azurerm_dns_zone_name       = data.terraform_remote_state.nonprod_shared.outputs.dns_zones["mxhhpdev_com"].name
  azurerm_resource_group_name = data.terraform_remote_state.nonprod_shared.outputs.dns_zones["mxhhpdev_com"].resource_group_name
  names                       = [format("%s-as", local.deprecated_prefix)]
  targets                     = [data.terraform_remote_state.nonprod_shared.outputs.azure_firewall_public_ip_resource_1.fqdn]
  type                        = "CNAME"

  azurerm_tags = local.tags
}
