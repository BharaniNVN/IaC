module "dns_record" {
  source = "../../../modules/terraform/dns_record"

  azurerm_dns_zone_name       = data.terraform_remote_state.prod_shared.outputs.dns_zones["matrixcarehhp_com"].name
  azurerm_resource_group_name = data.terraform_remote_state.prod_shared.outputs.dns_zones["matrixcarehhp_com"].resource_group_name
  names = formatlist("%s%s", var.deprecated_application_prefix, [
    "",
    "-fct-app",
  ])
  targets = [data.terraform_remote_state.shared.outputs.azure_firewall_public_ip_resource_prod_2.fqdn]
  type    = "CNAME"

  azurerm_tags = local.tags
}
