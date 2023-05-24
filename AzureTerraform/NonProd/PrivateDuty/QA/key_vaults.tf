resource "azurerm_key_vault" "all" {
  name                            = "${local.prefix}-all-kv"
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = "standard"
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = false
  purge_protection_enabled        = true

  tags = merge(
    local.tags,
    {
      "resource" = "key vault"
    },
  )
}

resource "azurerm_monitor_diagnostic_setting" "key_vault_all" {
  name                       = "SendAllToLogAnalytics"
  target_resource_id         = azurerm_key_vault.all.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  dynamic "log" {
    for_each = {
      "AuditEvent"                   = true,
      "AzurePolicyEvaluationDetails" = true,
    }

    content {
      category = log.key
      enabled  = log.value

      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_key_vault_access_policy" "terraform_all" {
  key_vault_id = azurerm_key_vault.all.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  certificate_permissions = [
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
    "SetIssuers",
    "Update",
  ]

  key_permissions = [
    "Backup",
    "Create",
    "Decrypt",
    "Delete",
    "Encrypt",
    "Get",
    "Import",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Sign",
    "UnwrapKey",
    "Update",
    "Verify",
    "WrapKey",
  ]

  secret_permissions = [
    "Backup",
    "Delete",
    "Get",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Set",
  ]
}

resource "azurerm_key_vault_access_policy" "azure_devops_spn_all" {
  key_vault_id = azurerm_key_vault.all.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azuread_service_principal.azure_devops_spn.object_id

  secret_permissions = [
    "Get",
    "List",
  ]
}

resource "azurerm_key_vault_access_policy" "aad_groups_all" {
  for_each = toset(data.azuread_groups.this.object_ids)

  key_vault_id = azurerm_key_vault.all.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = each.value

  certificate_permissions = [
    "Get",
    "GetIssuers",
    "List",
    "ListIssuers",
  ]

  key_permissions = [
    "Get",
    "List",
  ]

  secret_permissions = [
    "Get",
    "List",
  ]
}

resource "azurerm_key_vault_access_policy" "management_group_all" {
  key_vault_id = azurerm_key_vault.all.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.terraform_remote_state.nonprod_shared.outputs.key_vault_management_group_id

  certificate_permissions = [
    "Get",
    "List",
  ]

  key_permissions = [
    "Get",
    "List",
  ]

  secret_permissions = [
    "Get",
    "List",
  ]
}

resource "azurerm_user_assigned_identity" "key_vault_certificates" {
  name                = format("%s-key-vault-certificates-uai", local.prefix)
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  tags = merge(
    local.tags,
    {
      "resource" = "user assigned identity"
    },
  )
}

resource "azurerm_key_vault_access_policy" "key_vault_certificates" {
  key_vault_id = data.terraform_remote_state.nonprod_shared.outputs.initial_key_vault_id
  tenant_id    = azurerm_user_assigned_identity.key_vault_certificates.tenant_id
  object_id    = azurerm_user_assigned_identity.key_vault_certificates.principal_id

  secret_permissions = [
    "Get",
    "List",
  ]
}

resource "azurerm_key_vault" "all_managed" {
  name                            = "${local.prefix}-all-managed-kv"
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = "standard"
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = false
  purge_protection_enabled        = false

  tags = merge(
    local.tags,
    {
      "resource" = "key vault"
    },
  )
}

resource "azurerm_monitor_diagnostic_setting" "key_vault_all_managed" {
  name                       = "SendAllToLogAnalytics"
  target_resource_id         = azurerm_key_vault.all_managed.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  dynamic "log" {
    for_each = {
      "AuditEvent"                   = true,
      "AzurePolicyEvaluationDetails" = true,
    }

    content {
      category = log.key
      enabled  = log.value

      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_key_vault_access_policy" "terraform_all_managed" {
  key_vault_id = azurerm_key_vault.all_managed.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  certificate_permissions = [
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
    "SetIssuers",
    "Update",
  ]

  key_permissions = [
    "Backup",
    "Create",
    "Decrypt",
    "Delete",
    "Encrypt",
    "Get",
    "Import",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Sign",
    "UnwrapKey",
    "Update",
    "Verify",
    "WrapKey",
  ]

  secret_permissions = [
    "Backup",
    "Delete",
    "Get",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Set",
  ]
}

resource "azurerm_key_vault_access_policy" "azure_devops_spn_all_managed" {
  key_vault_id = azurerm_key_vault.all_managed.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azuread_service_principal.azure_devops_spn.object_id

  secret_permissions = [
    "Get",
    "List",
  ]
}

resource "azurerm_key_vault_access_policy" "aad_groups_all_managed" {
  for_each = toset(data.azuread_groups.this.object_ids)

  key_vault_id = azurerm_key_vault.all_managed.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = each.value

  certificate_permissions = [
    "Get",
    "GetIssuers",
    "List",
    "ListIssuers",
  ]

  key_permissions = [
    "Get",
    "List",
  ]

  secret_permissions = [
    "Get",
    "List",
  ]
}

resource "azurerm_key_vault_access_policy" "management_group_all_managed" {
  key_vault_id = azurerm_key_vault.all_managed.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.terraform_remote_state.nonprod_shared.outputs.key_vault_management_group_id

  certificate_permissions = [
    "Get",
    "List",
  ]

  key_permissions = [
    "Get",
    "List",
  ]

  secret_permissions = [
    "Get",
    "List",
  ]
}

resource "azurerm_key_vault_secret" "pipeline_variables_all" {
  for_each = local.pipeline_variables_all

  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault_access_policy.terraform_all.key_vault_id

  tags = merge(
    local.tags,
    {
      "resource" = "key vault secret"
    },
  )
}

resource "azurerm_key_vault_secret" "pipeline_variables_all_managed" {
  for_each = local.pipeline_variables_all_managed

  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault_access_policy.terraform_all_managed.key_vault_id

  tags = merge(
    local.tags,
    {
      "resource" = "key vault secret"
    },
  )
}