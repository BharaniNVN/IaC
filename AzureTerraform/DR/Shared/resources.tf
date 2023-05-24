resource "azurerm_resource_group" "resources" {
  name     = "${local.deprecated_prefix}-resources-rg"
  location = var.location

  tags = merge(
    local.tags,
    {
      "resource" = "resource group"
    },
  )
}

module "application_insights" {
  source = "../../../modules/terraform/application_insights"

  name                             = format("%s-appins", local.deprecated_prefix)
  resource_group_resource          = azurerm_resource_group.resources
  log_analytics_workspace_resource = azurerm_log_analytics_workspace.this
  retention_in_days                = 30

  tags = local.tags
}

resource "azurerm_storage_account" "dsc" {
  name                            = "${local.deprecated_prefix}dscstg"
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

resource "azurerm_key_vault" "this" {
  name                            = "${local.deprecated_prefix}-keyvault-bthhh"
  location                        = azurerm_resource_group.resources.location
  resource_group_name             = azurerm_resource_group.resources.name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = "standard"
  enabled_for_disk_encryption     = true
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

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "SendAllToLogAnalytics"
  target_resource_id         = azurerm_key_vault.this.id
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
