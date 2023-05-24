resource "azurerm_resource_group" "deprecated_rg" {
  name     = "${local.deprecated_prefix}-rg"
  location = var.location

  tags = merge(
    local.tags,
    {
      "resource" = "resource group"
    },
  )
}

resource "azurerm_storage_account" "deprecated_sa" {
  name                      = "${local.deprecated_prefix}sa"
  location                  = azurerm_resource_group.deprecated_rg.location
  resource_group_name       = azurerm_resource_group.deprecated_rg.name
  account_kind              = "BlobStorage"
  account_tier              = "Standard"
  account_replication_type  = "GRS"
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"

  tags = merge(
    local.tags,
    {
      "resource" = "storage account"
    },
  )
}

resource "azurerm_resource_group" "resources" {
  name     = "${local.deprecated_prefix2}-resources-rg"
  location = var.location

  tags = merge(
    local.tags,
    {
      "resource" = "resource group"
    },
  )
}

resource "azurerm_storage_account" "dsc" {
  name                            = "${local.deprecated_prefix2}dscstg"
  resource_group_name             = azurerm_resource_group.resources.name
  location                        = azurerm_resource_group.resources.location
  account_kind                    = "Storage"
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
  enable_https_traffic_only       = true
  min_tls_version                 = "TLS1_2"

  tags = merge(
    local.tags,
    {
      "resource" = "storage account"
    },
  )
}

resource "azurerm_storage_container" "dsc" {
  name                  = "dsc"
  storage_account_name  = azurerm_storage_account.dsc.name
  container_access_type = "private"
}

resource "azurerm_key_vault" "nonprod_shared" {
  name                     = "mxhhp-${local.prefix}-kv"
  location                 = azurerm_resource_group.resources.location
  resource_group_name      = azurerm_resource_group.resources.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = "standard"
  purge_protection_enabled = true

  tags = merge(
    local.tags,
    {
      "resource" = "key vault"
    },
  )
}

resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = azurerm_key_vault.nonprod_shared.id
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

resource "azurerm_key_vault_access_policy" "management_group" {
  key_vault_id = azurerm_key_vault.nonprod_shared.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azuread_group.key_vault_management.id

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

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "SendAllToLogAnalytics"
  target_resource_id         = azurerm_key_vault.nonprod_shared.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.nonprod.id

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

resource "azurerm_eventhub_namespace" "alienvault" {
  name                = "${local.deprecated_prefix2}-eventhubnamespace-alienvault"
  location            = azurerm_resource_group.resources.location
  resource_group_name = azurerm_resource_group.resources.name
  sku                 = "Basic"
  capacity            = 1

  tags = merge(
    local.tags,
    {
      "resource" = "eventhub namespace"
    },
  )
}

resource "azurerm_eventhub" "alienvault" {
  name                = "${local.deprecated_prefix2}-eventhub-alienvault"
  namespace_name      = azurerm_eventhub_namespace.alienvault.name
  resource_group_name = azurerm_resource_group.resources.name
  partition_count     = 2
  message_retention   = 1
}

resource "azurerm_eventhub_namespace_authorization_rule" "alienvault" {
  name                = "AlienvaultAccessPolicy"
  namespace_name      = azurerm_eventhub_namespace.alienvault.name
  resource_group_name = azurerm_resource_group.resources.name
  listen              = true
  send                = true
  manage              = true
}

resource "azurerm_security_center_subscription_pricing" "this" {
  tier          = "Standard"
  resource_type = "StorageAccounts"
}

resource "azurerm_security_center_workspace" "security_workspace" {
  scope        = local.subscription_resource_id
  workspace_id = azurerm_log_analytics_workspace.nonprod.id

  depends_on = [azurerm_security_center_subscription_pricing.this]
}
