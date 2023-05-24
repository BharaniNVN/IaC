locals {
  aad_domain         = lower(data.azuread_domains.this.domains[0].domain_name)
  aad_groups_members = distinct(flatten([for g in data.azuread_group.this : g.members]))
  prefix             = lower(format("%s%s", var.env, var.resource_prefix))
  secrets = {
    "AzureSubscriptionId"          = data.azurerm_subscription.primary.subscription_id
    "AzureTenantId"                = data.azurerm_subscription.primary.tenant_id
    "PipelinesAgentSubnetResource" = jsonencode(merge(azurerm_subnet.pipelines_agent_aci, { "location" = azurerm_virtual_network.pipelines_agent.location }))
    "TerraformAppClientId"         = azuread_application.terraform.application_id
    "TerraformSaAccessKey"         = azurerm_storage_account.this.primary_access_key
  }
  tags = merge(
    var.tags,
    {
      "environment" = var.env
    },
  )
}
