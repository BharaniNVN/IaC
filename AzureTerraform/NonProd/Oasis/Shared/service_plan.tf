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

resource "azurerm_service_plan" "this" {
  name                = "${local.deprecated_prefix}-asp"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Windows"
  sku_name            = "S2"

  tags = merge(
    local.tags,
    {
      "resource" = "service plan"
    },
  )
}
