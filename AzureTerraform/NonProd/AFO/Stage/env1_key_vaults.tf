resource "azurerm_key_vault" "env1" {
  name                            = "${local.prefix}-env1-kv"
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = "standard"
  enabled_for_disk_encryption     = true
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = false

  tags = merge(
    local.tags,
    {
      "resource" = "key vault"
    },
  )
}

resource "azurerm_key_vault" "env1_managed" {
  name                            = "${local.prefix}-env1-managed-kv"
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = "standard"
  enabled_for_disk_encryption     = true
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = false

  tags = merge(
    local.tags,
    {
      "resource" = "key vault"
    },
  )
}

resource "azurerm_monitor_diagnostic_setting" "key_vault_env1" {
  name                       = "SendAllToLogAnalytics"
  target_resource_id         = azurerm_key_vault.env1.id
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

resource "azurerm_monitor_diagnostic_setting" "key_vault_env1_managed" {
  name                       = "SendAllToLogAnalytics"
  target_resource_id         = azurerm_key_vault.env1_managed.id
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

resource "azurerm_key_vault_access_policy" "terraform_env1" {
  key_vault_id = azurerm_key_vault.env1.id
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

resource "azurerm_key_vault_access_policy" "terraform_env1_managed" {
  key_vault_id = azurerm_key_vault.env1_managed.id
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

resource "azurerm_key_vault_access_policy" "management_group_env1" {
  key_vault_id = azurerm_key_vault.env1.id
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

resource "azurerm_key_vault_access_policy" "management_group_env1_managed" {
  key_vault_id = azurerm_key_vault.env1_managed.id
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

resource "azurerm_key_vault_access_policy" "azure_devops_spn_env1" {
  key_vault_id = azurerm_key_vault.env1.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azuread_service_principal.azure_devops_spn.id

  secret_permissions = [
    "Get",
    "List",
  ]
}

resource "azurerm_key_vault_access_policy" "azure_devops_spn_env1_managed" {
  key_vault_id = azurerm_key_vault.env1_managed.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azuread_service_principal.azure_devops_spn.id

  secret_permissions = [
    "Get",
    "List",
  ]
}
