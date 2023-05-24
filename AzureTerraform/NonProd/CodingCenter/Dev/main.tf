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

resource "azurerm_log_analytics_workspace" "this" {
  name                = "${local.deprecated_prefix}-la"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = merge(
    local.tags,
    {
      "resource" = "log analytics workspace"
    },
  )
}