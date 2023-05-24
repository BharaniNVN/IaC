resource "azurerm_resource_group" "this" {
  name     = "${local.deprecated_prefix}-rg"
  location = var.location

  tags = merge(
    local.tags,
    {
      "resource" = "resource group"
    }
  )
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

resource "azurerm_log_analytics_solution" "this" {
  for_each = toset(var.solution_name)

  solution_name         = each.key
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  workspace_resource_id = azurerm_log_analytics_workspace.this.id
  workspace_name        = azurerm_log_analytics_workspace.this.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/${each.key}"
  }
}

module "oms_cosmosdb" {
  source = "../../../modules/terraform/oms_cosmosdb"

  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  workspace_name      = azurerm_log_analytics_workspace.this.name
}

module "application_insights" {
  source = "../../../modules/terraform/application_insights"

  name                             = format("%s-appins", local.deprecated_prefix)
  resource_group_resource          = azurerm_resource_group.this
  log_analytics_workspace_resource = azurerm_log_analytics_workspace.this

  tags = local.tags
}
