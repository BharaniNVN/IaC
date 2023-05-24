resource "azurerm_resource_group" "this" {
  name     = "${local.deprecated_prefix}-rg"
  location = var.location

  tags = merge(
    local.tags,
    {
      "resource" = "resource group"
    },
  )
}

module "application_insights" {
  source = "../../../../modules/terraform/application_insights"

  name                    = format("%s-appins", local.deprecated_prefix)
  resource_group_resource = azurerm_resource_group.this

  tags = local.tags
}
