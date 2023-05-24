resource "azurerm_resource_group_template_deployment" "this" {
  name                = "oms_fw_solution"
  resource_group_name = var.resource_group_name
  deployment_mode     = "Incremental"
  template_content    = file("${path.module}/azure_firewall_solution.json")

  parameters_content = jsonencode({
    "location"      = { "value" = var.location },
    "resourcegroup" = { "value" = var.resource_group_name },
    "workspace"     = { "value" = var.workspace_name },
  })

  tags = merge(
    var.tags,
    {
      "resource" = "resource group template deployment"
    },
  )
}
