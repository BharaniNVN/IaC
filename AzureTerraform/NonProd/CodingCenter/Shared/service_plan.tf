resource "azurerm_service_plan" "this" {
  name                = "${local.deprecated_prefix}-asp"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Windows"
  sku_name            = var.sku_name

  tags = merge(
    local.tags,
    {
      "resource" = "service plan"
    },
  )
}
