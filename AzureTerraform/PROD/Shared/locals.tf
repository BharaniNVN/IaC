locals {
  aad_domain_name               = lower(data.azuread_domains.aad_domains.domains[0].domain_name)
  application_name_data_gateway = "cdwaz-datagateway-ad-app"
  application_name_securends    = format("%s-securends-ad-app", local.deprecated_prefix)
  application_name_vm_operator  = format("%s-vm_operator", local.deprecated_prefix)
  deprecated_prefix             = lower(format("%s", var.application))
  dmz_domain_dn                 = join(",", formatlist("DC=%s", split(".", var.dmz_domain)))
  dmz_domain_netbios_name       = data.external.dmz_domain_information.result.netbiosname
  internal_domain_dn            = join(",", formatlist("DC=%s", split(".", var.internal_domain)))
  internal_domain_netbios_name  = data.external.internal_domain_information.result.netbiosname
  prefix                        = lower(format("%s%s", var.environment_prefix, var.application_prefix))
  separator                     = "_"
  subnets                       = { for s in [azurerm_subnet.dmz_subnet, azurerm_subnet.cawprod_subnet] : lower(s.name) => s.id }
  subscription_resource_id      = format("/subscriptions/%s", data.azurerm_client_config.current.subscription_id)

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

  app01 = "oasis"
  app02 = "oasis-fct-app"
  app03 = "codingcenter"
  app04 = "myanalytics"
}
