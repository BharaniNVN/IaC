resource "azurerm_key_vault" "this" {
  name                            = format("%sTerraformKv", var.env)
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  tenant_id                       = data.azurerm_subscription.primary.tenant_id
  sku_name                        = "standard"
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = true

  tags = merge(
    local.tags,
    {
      "resource" = "key vault"
    },
  )
}

resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azurerm_subscription.primary.tenant_id
  object_id    = azuread_service_principal.terraform.object_id

  certificate_permissions = [
    "Get",
  ]

  key_permissions = [
    "Get",
  ]

  secret_permissions = [
    "Get",
  ]
}

resource "azurerm_key_vault_access_policy" "groups" {
  for_each = var.groups

  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azurerm_subscription.primary.tenant_id
  object_id    = data.azuread_group.this[each.value].id

  certificate_permissions = [
    "Backup",
    "Create",
    "Delete",
    "DeleteIssuers",
    "Get",
    "GetIssuers",
    "Import",
    "List",
    "ListIssuers",
    "ManageContacts",
    "ManageIssuers",
    "Recover",
    "Restore",
    "SetIssuers",
    "Update",
  ]

  key_permissions = [
    "Backup",
    "Create",
    "Delete",
    "Get",
    "Import",
    "List",
    "Recover",
    "Restore",
    "Update",
  ]

  secret_permissions = [
    "Backup",
    "Delete",
    "Get",
    "List",
    "Recover",
    "Restore",
    "Set",
  ]
}

resource "azurerm_management_lock" "key_vault" {
  name       = "Essential Key Vault"
  scope      = azurerm_key_vault.this.id
  lock_level = "CanNotDelete"
  notes      = "Locked because it's needed by a Terraform application."
}

resource "azurerm_key_vault_secret" "this" {
  for_each = local.secrets

  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.this.id

  tags = merge(
    local.tags,
    {
      "resource" = "key vault secret"
    },
  )

  depends_on = [
    azurerm_key_vault_access_policy.groups
  ]

  lifecycle {
    ignore_changes = [content_type]
  }
}
