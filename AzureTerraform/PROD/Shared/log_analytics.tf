resource "azurerm_resource_group" "log_analytics" {
  name     = "${local.deprecated_prefix}-log-analytics-rg"
  location = var.secondary_location

  tags = merge(
    local.tags,
    {
      "resource" = "resource group"
    },
  )
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "${local.deprecated_prefix}-log-analytics-bthhh"
  location            = azurerm_resource_group.log_analytics.location
  resource_group_name = azurerm_resource_group.log_analytics.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = merge(
    local.tags,
    {
      "resource" = "log analytics workspace"
    },
  )
}

resource "azurerm_log_analytics_solution" "oms_solution" {
  for_each = toset(var.solution_name)

  solution_name         = each.key
  location              = azurerm_resource_group.log_analytics.location
  resource_group_name   = azurerm_resource_group.log_analytics.name
  workspace_resource_id = azurerm_log_analytics_workspace.this.id
  workspace_name        = azurerm_log_analytics_workspace.this.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/${each.key}"
  }
}

module "oms_cosmosdb" {
  source = "../../../modules/terraform/oms_cosmosdb"

  location            = azurerm_resource_group.log_analytics.location
  resource_group_name = azurerm_resource_group.log_analytics.name
  workspace_name      = azurerm_log_analytics_workspace.this.name
}
