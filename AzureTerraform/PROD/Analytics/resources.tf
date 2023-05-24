resource "azurerm_resource_group" "analytics" {
  name     = "${local.deprecated_prefix}-rg"
  location = var.location

  tags = merge(
    local.tags,
    {
      "resource" = "resource group"
    },
  )
}

resource "azurerm_storage_account" "analytics" {
  name                      = "${local.deprecated_prefix}stg"
  resource_group_name       = azurerm_resource_group.analytics.name
  location                  = azurerm_resource_group.analytics.location
  account_kind              = "StorageV2"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"

  tags = merge(
    local.tags,
    {
      "resource" = "storage account"
    },
  )
}

resource "azurerm_storage_container" "hhpstaging" {
  name                  = "hhpstaging"
  storage_account_name  = azurerm_storage_account.analytics.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "trigger" {
  name                  = "trigger"
  storage_account_name  = azurerm_storage_account.analytics.name
  container_access_type = "private"
}

resource "azurerm_key_vault" "this" {
  name                            = "mxhhp-${local.deprecated_prefix}-kv"
  location                        = azurerm_resource_group.analytics.location
  resource_group_name             = azurerm_resource_group.analytics.name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = "standard"
  enabled_for_disk_encryption     = true
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = true

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    certificate_permissions = [
      "create",
      "delete",
      "deleteissuers",
      "get",
      "getissuers",
      "import",
      "list",
      "listissuers",
      "managecontacts",
      "manageissuers",
      "setissuers",
      "update",
    ]

    key_permissions = [
      "backup",
      "create",
      "decrypt",
      "delete",
      "encrypt",
      "get",
      "import",
      "list",
      "purge",
      "recover",
      "restore",
      "sign",
      "unwrapKey",
      "update",
      "verify",
      "wrapKey",
    ]

    secret_permissions = [
      "backup",
      "delete",
      "get",
      "list",
      "purge",
      "recover",
      "restore",
      "set",
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_data_factory.this.identity[0].principal_id

    secret_permissions = [
      "get",
      "list",
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.terraform_remote_state.prod_shared.outputs.key_vault_management_group_id

    certificate_permissions = [
      "get",
      "list",
    ]

    key_permissions = [
      "get",
      "list",
    ]

    secret_permissions = [
      "get",
      "list",
    ]
  }

  tags = merge(
    local.tags,
    {
      "resource" = "key vault"
    },
  )
}

resource "azurerm_key_vault_secret" "blob_storage_connection_string" {
  name         = "blobStorageConnectionString"
  value        = azurerm_storage_account.analytics.primary_connection_string
  key_vault_id = azurerm_key_vault.this.id

  tags = merge(
    local.tags,
    {
      "resource" = "key vault secret"
    },
  )
}

resource "azurerm_key_vault_secret" "bt_datamart_connection_string" {
  name         = "btDatamartConnectionString"
  value        = "Data Source=${azurerm_sql_server.analytics.fully_qualified_domain_name};Initial Catalog=${azurerm_sql_database.analytics.name};User id=${var.azure_sql_admin_user};Password=${var.sql_sa_pswd};Encrypt=yes;trustServerCertificate=true"
  key_vault_id = azurerm_key_vault.this.id

  tags = merge(
    local.tags,
    {
      "resource" = "key vault secret"
    },
  )
}

resource "azurerm_key_vault_secret" "hhp_staging_db_connection_string" {
  name         = "hhpStagingDbConnectionString"
  value        = "Data Source=${lookup(module.sql.name_with_ip_address_and_port, "prodana-sql")};Initial Catalog=BtStaging;User id=${var.sql_login_adfuser_name};Password=${var.sql_login_adfuser_pswd};Encrypt=yes;trustServerCertificate=true"
  key_vault_id = azurerm_key_vault.this.id

  tags = merge(
    local.tags,
    {
      "resource" = "key vault secret"
    },
  )
}

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "SendAllToLogAnalytics"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = data.terraform_remote_state.prod_shared.outputs.log_analytics.id

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
