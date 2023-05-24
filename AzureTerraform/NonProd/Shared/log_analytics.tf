resource "azurerm_resource_group" "log_analytics" {
  name     = "${local.deprecated_prefix2}-log-analytics-rg"
  location = var.location

  tags = merge(
    local.tags,
    {
      "resource" = "resource group"
    },
  )
}

resource "azurerm_log_analytics_workspace" "nonprod" {
  name                = "${local.deprecated_prefix2}-log-analytics-hhh"
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

resource "azurerm_log_analytics_solution" "nonprod_solution" {
  for_each = toset(var.solution_name)

  solution_name         = each.key
  location              = azurerm_resource_group.log_analytics.location
  resource_group_name   = azurerm_resource_group.log_analytics.name
  workspace_resource_id = azurerm_log_analytics_workspace.nonprod.id
  workspace_name        = azurerm_log_analytics_workspace.nonprod.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/${each.key}"
  }
}

resource "azurerm_log_analytics_workspace" "fw_la" {
  name                = "${local.deprecated_prefix2}-fw-log-analytics-hhh"
  location            = azurerm_resource_group.fw_rg.location
  resource_group_name = azurerm_resource_group.fw_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = merge(
    local.tags,
    {
      "resource" = "log analytics workspace"
    },
  )
}

module "oms_fw" {
  source = "../../../modules/terraform/oms_azure_firewall"

  location            = azurerm_resource_group.fw_rg.location
  resource_group_name = azurerm_resource_group.fw_rg.name
  workspace_name      = azurerm_log_analytics_workspace.fw_la.name
}

module "oms_cosmosdb" {
  source = "../../../modules/terraform/oms_cosmosdb"

  location            = azurerm_resource_group.log_analytics.location
  resource_group_name = azurerm_resource_group.log_analytics.name
  workspace_name      = azurerm_log_analytics_workspace.nonprod.name
}
