module "dns_record" {
  source = "../../../../modules/terraform/dns_record"

  azurerm_dns_zone_name       = data.terraform_remote_state.nonprod_shared.outputs.dns_zones["mxhhpdev_com"].name
  azurerm_resource_group_name = data.terraform_remote_state.nonprod_shared.outputs.dns_zones["mxhhpdev_com"].resource_group_name
  names = formatlist("%s-%s", local.prefix, [
    "authapi",
    "configextapi",
    "extapi",
    "gc",
    "integextapi",
    "integextwcf",
    "login",
    "missioncontrol",
    "mobileapi",
    "secure1",
    "secure2",
    "blue-secure",
    "green-secure",
    "red-secure",
    "gold-secure",
    "silver-secure",
    "black-secure",
    "purple-secure",
    "orange-secure",
    "magenta-secure",
    "violet-secure",
  ])
  targets = [data.terraform_remote_state.nonprod_shared.outputs.azure_firewall_public_ip_resource_1.fqdn]
  type    = "CNAME"

  azurerm_tags = local.tags
}