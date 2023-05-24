resource "azurerm_resource_group_template_deployment" "this" {
  name                = format("%s-audit", var.sql_server_name)
  resource_group_name = var.resource_group_name
  deployment_mode     = "Incremental"
  template_content    = file("${path.module}/az_sql_server_audit.json")

  parameters_content = jsonencode({
    "eventhub_name"             = { "value" = var.eventhub_name },
    "eventhub_policy_id"        = { "value" = var.eventhub_policy_id },
    "log_analytics_resource_id" = { "value" = var.log_analytics_resource_id },
    "sql_server_name"           = { "value" = var.sql_server_name },
  })

  tags = merge(
    var.tags,
    {
      "resource" = "resource group template deployment"
    },
  )
}
