locals {
  aad_domain_name   = lower(data.azuread_domains.aad_domains.domains[0].domain_name)
  deprecated_prefix = lower(var.application_prefix)
  dmz_domain_dn     = join(",", formatlist("DC=%s", split(".", var.dmz_domain)))
  dsc_storage_container = merge(
    azurerm_storage_container.dsc,
    {
      "resource_group_name" = azurerm_resource_group.resources.name
    },
  )
  subnets = { for s in [azurerm_subnet.dmz_subnet, azurerm_subnet.cawprod_subnet] : lower(s.name) => s.id }
  tags = merge(
    var.tags,
    {
      "application" = var.application
      "environment" = var.environment
    },
  )
}
