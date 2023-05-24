module "dns_record_enablement" {
  source = "../../../modules/terraform/dns_record"

  azurerm_dns_zone_name       = var.dns_zone_name
  azurerm_resource_group_name = var.dns_zone_resource_group_name

  names   = ["enablement"]
  targets = [azurerm_public_ip.fw_pip_1.fqdn]
  type    = "CNAME"

  azurerm_tags = local.tags
}
