resource "azurerm_resource_group" "this" {
  name     = "${local.prefix}-rg"
  location = var.location

  tags = merge(
    local.tags,
    {
      "resource" = "resource group"
    },
  )
}

resource "azurerm_app_service_plan" "this" {
  name                = "${local.prefix}-sp"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  kind                = "FunctionApp"

  sku {
    tier = "Standard"
    size = "S1"
  }

  tags = merge(
    local.tags,
    {
      "resource" = "service plan"
    },
  )
}