locals {
  pipelines_agent_subnet_resource = jsondecode(data.azurerm_key_vault_secret.pipelines_agent_subnet_resource.value)
  tags = merge(
    var.tags,
    {
      "environment" = var.prefix
    },
  )
}
