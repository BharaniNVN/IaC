module "dns_record" {
  source = "../../../../modules/terraform/dns_record"

  azurerm_dns_zone_name       = data.terraform_remote_state.nonprod_shared.outputs.dns_zones["mxhhpdev_com"].name
  azurerm_resource_group_name = data.terraform_remote_state.nonprod_shared.outputs.dns_zones["mxhhpdev_com"].resource_group_name
  names = [for i in [
    local.pipeline_variables_all_managed["apiFQDN"],
    local.pipeline_variables_all_managed["appFQDN"],
    local.pipeline_variables_all_managed["authFQDN"],
    local.pipeline_variables_all_managed["clickonceFQDN"],
    local.pipeline_variables_all_managed["idmApiFQDN"],
    local.pipeline_variables_all_managed["managementFQDN"],
    local.pipeline_variables_all_managed["mgmtinterfaceFQDN"],
    local.pipeline_variables_all_managed["reportsFQDN"],
    local.pipeline_variables_all_managed["telephonyApiFQDN"],
    local.pipeline_variables_all_managed["telephonyServiceFQDN"],
    local.pipeline_variables_all_managed["clickonceHistoricFQDN"],
    local.pipeline_variables_all_managed["clickonceRegressionFQDN"],
    local.pipeline_variables_all_managed["clickonceReleaseFQDN"],
  ] : split(".", i)[0]]
  targets = [data.terraform_remote_state.nonprod_shared.outputs.azure_firewall_public_ip_resource_1.fqdn]
  type    = "CNAME"

  azurerm_tags = local.tags
}
