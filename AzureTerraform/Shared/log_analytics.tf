resource "azurerm_log_analytics_workspace" "hub_la" {
  name                = "${var.prefix}-fw-log-analytics-bthhh"
  location            = azurerm_resource_group.fw_rg.location
  resource_group_name = azurerm_resource_group.fw_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 90

  tags = merge(
    local.tags,
    {
      "resource" = "log analytics workspace"
    },
  )
}

module "oms_fw" {
  source = "../../modules/terraform/oms_azure_firewall"

  location            = azurerm_resource_group.fw_rg.location
  resource_group_name = azurerm_resource_group.fw_rg.name
  workspace_name      = azurerm_log_analytics_workspace.hub_la.name
}
