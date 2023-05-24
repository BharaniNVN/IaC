resource "azurerm_app_service_plan" "this" {
  name                = "${local.deprecated_prefix}-asp"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  sku {
    tier = var.asp_tier
    size = var.asp_size
  }

  tags = merge(
    local.tags,
    {
      "resource" = "service plan"
    },
  )
}
