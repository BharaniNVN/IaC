locals {
  aad_domain         = lower(data.azuread_domains.this.domains[0].domain_name)
  aad_groups_ids     = [for g in data.azuread_group.this : g.id]
  aad_groups_members = distinct(flatten([for g in data.azuread_group.this : setsubtract(g.members, local.aad_groups_ids)]))
  prefix             = lower(format("%s%s", var.env, var.resource_prefix))
  secrets = {
    "AzureSubscriptionId"  = data.azurerm_subscription.primary.subscription_id
    "AzureTenantId"        = data.azurerm_subscription.primary.tenant_id
    "TerraformAppClientId" = azuread_application.terraform.application_id
    "TerraformSaAccessKey" = azurerm_storage_account.this.primary_access_key
  }
  tags = merge(
    var.tags,
    {
      "environment" = var.env
    },
  )
}
