locals {
  application_name_data_gateway   = "cdwaz-datagateway-ad-app"
  application_name_securends      = format("%s-securends-ad-app", local.deprecated_prefix2)
  application_name_vm_operator    = format("%s-vm_operator", local.deprecated_prefix2)
  domain_dn                       = join(",", formatlist("DC=%s", split(".", var.domain_name)))
  domain_netbios_name             = data.external.domain_information.result.netbiosname
  prefix                          = lower(format("%s%s", var.environment_prefix, var.application_prefix))
  deprecated_prefix               = format("bthhhterraform%s", local.deprecated_prefix2)
  deprecated_prefix2              = lower(var.application)
  pipelines_agent_subnet_resource = jsondecode(data.azurerm_key_vault_secret.pipelines_agent_subnet_resource.value)
  separator                       = "_"
  subnets                         = { for s in [azurerm_subnet.shared] : lower(s.name) => s.id }
  subscription_resource_id        = format("/subscriptions/%s", data.azurerm_client_config.current.subscription_id)
  dns_objects_ad                  = flatten([for each in var.dns_records_external : [for ip in data.dns_a_record_set.dns_records_external[format("%s.%s", each.name, each.zone)].addrs : merge(each, { "ip" = ip })]])
  dns_objects_fw                  = [for each in var.dns_records_external : merge(each, { "ip" = data.dns_a_record_set.dns_records_external[format("%s.%s", each.name, each.zone)].addrs })]
  dsc_storage_container = merge(
    azurerm_storage_container.dsc,
    {
      "resource_group_name" = azurerm_resource_group.resources.name
    },
  )
  tags = merge(
    var.tags,
    {
      "application" = var.application
      "environment" = var.environment
    },
  )
  app01 = "devoasis-as"
  app02 = "devoasis-fct-app"
  app03 = "qaoasis-as"
  app04 = "qaoasis-fct-app"
  app05 = "stgocs-as"
  app06 = "stgocs-fct-app"
  app07 = "hfxocs-as"
  app08 = "hfxocs-fct-app"
  app09 = "devcodingcenter-as"
  app10 = "stagecodingcenter-as"
  app11 = "devana-as"
  app12 = "intana-as"
  app13 = "stageana-as"
  app14 = "hotfixana-as"
  app15 = "intcrml-app"
  app16 = "intcrml-api"
}
