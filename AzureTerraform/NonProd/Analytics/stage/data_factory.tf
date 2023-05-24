resource "azurerm_data_factory" "this" {
  name                = "${local.deprecated_prefix}-adf"
  location            = var.location
  resource_group_name = azurerm_resource_group.analytics.name

  identity {
    type = "SystemAssigned"
  }

  tags = merge(
    local.tags,
    {
      "resource" = "data factory"
    },
  )
}

resource "azurerm_template_deployment" "ir" {
  name                = "${local.deprecated_prefix}-integration-runtime"
  resource_group_name = azurerm_resource_group.analytics.name
  deployment_mode     = "Incremental"
  template_body       = file("./integration_runtime.json")

  parameters = {
    "existingDataFactoryName" = azurerm_data_factory.this.name
    "IntegrationRuntimeName"  = var.ir_name
  }
}
