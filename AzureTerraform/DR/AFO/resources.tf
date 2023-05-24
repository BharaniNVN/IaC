resource "azurerm_resource_group" "resources" {
  name     = "${local.prefix}-resources-rg"
  location = var.location

  tags = merge(
    local.tags,
    {
      "resource" = "resource group"
    },
  )
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "${local.prefix}-la"
  location            = azurerm_resource_group.resources.location
  resource_group_name = azurerm_resource_group.resources.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = merge(
    local.tags,
    {
      "resource" = "log analytics workspace"
    },
  )
}

resource "azurerm_log_analytics_solution" "this" {
  for_each = toset(var.solution_name)

  solution_name         = each.key
  location              = azurerm_resource_group.resources.location
  resource_group_name   = azurerm_resource_group.resources.name
  workspace_resource_id = azurerm_log_analytics_workspace.this.id
  workspace_name        = azurerm_log_analytics_workspace.this.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/${each.key}"
  }
}

module "application_insights_afo" {
  source = "../../../modules/terraform/application_insights"

  name                             = format("%s-appins", local.prefix)
  resource_group_resource          = azurerm_resource_group.resources
  log_analytics_workspace_resource = azurerm_log_analytics_workspace.this
  retention_in_days                = 30

  web_tests = {
    "login" = {
      "geo_locations" = [
        "Central US",
        "East US",
        "North Central US",
        "South Central US",
        "West US",
      ],
      "timeout" = 120
      "url"     = local.login_url
    }
  }

  tags = local.tags
}

module "application_insights_mobileapi" {
  source = "../../../modules/terraform/application_insights"

  name                             = format("%s-mobileapi-appins", local.prefix)
  resource_group_resource          = azurerm_resource_group.resources
  log_analytics_workspace_resource = azurerm_log_analytics_workspace.this
  retention_in_days                = 30

  tags = local.tags
}

module "application_insights_gc" {
  source = "../../../modules/terraform/application_insights"

  name                             = format("%s-gc-appins", local.prefix)
  resource_group_resource          = azurerm_resource_group.resources
  log_analytics_workspace_resource = azurerm_log_analytics_workspace.this
  retention_in_days                = 30

  web_tests = {
    "groundcontrol" = {
      "geo_locations" = [
        "Central US",
        "East US",
        "North Central US",
        "South Central US",
        "West US",
      ],
      "timeout" = 120
      "url"     = local.pipeline_variables_all_managed["groundcontrolWebUrl"]
    }
  }

  tags = local.tags
}

module "sendgrid_apikey" {
  source = "../../../modules/terraform/sendgrid_apikey"

  api_key_name                   = format("%s-mail", local.prefix)
  key_vault_id                   = azurerm_key_vault_access_policy.terraform_all_managed.key_vault_id
  management_api_key_value       = data.terraform_remote_state.prod_shared.outputs.sendgrid_management_api_key
  secret_name                    = format("%sSendGridMailApiKey", local.prefix)
  force_sendgrid_apikey_redeploy = var.force_sendgrid_apikey_redeploy
}

resource "azurerm_user_assigned_identity" "key_vault_certificates" {
  name                = format("%s-key-vault-certificates-uai", local.prefix)
  resource_group_name = azurerm_resource_group.resources.name
  location            = azurerm_resource_group.resources.location

  tags = merge(
    local.tags,
    {
      "resource" = "user assigned identity"
    },
  )
}

resource "azurerm_key_vault_access_policy" "key_vault_certificates" {
  key_vault_id = data.terraform_remote_state.dr_shared.outputs.initial_key_vault_id
  tenant_id    = azurerm_user_assigned_identity.key_vault_certificates.tenant_id
  object_id    = azurerm_user_assigned_identity.key_vault_certificates.principal_id

  secret_permissions = [
    "Get",
    "List",
  ]
}

module "machine_key" {
  source = "../../../modules/terraform/machine_key_generator"

  key_vault_id               = azurerm_key_vault_access_policy.terraform_all_managed.key_vault_id
  force_machine_key_redeploy = var.force_machine_key_redeploy
}

# Applies to:
# sql_shared_hybrid_worker_backup_storage_key_operator
# sql2_hybrid_worker_backup_storage_key_operator
# sql4_hybrid_worker_backup_storage_key_operator
# sql5_hybrid_worker_backup_storage_key_operator
# sql6_hybrid_worker_backup_storage_key_operator
# sql7_hybrid_worker_backup_storage_key_operator
# sql8_hybrid_worker_backup_storage_key_operator
# Since for_each requires a map or set and local.db_restore_rbac_map is a list of objects it has to be converted on the fly.
# The key part:
# "${item.vm_name}.${item.storage_id}"
# is used only for iteration basically and has to be unique, hence it contains of the item.vm_name and item.storage_id.
# The value part:
# Inherits the whole item from the local.db_restore_rbac_map.
# For loop produces a type value that has following structure (map of objects on the root level):
# {
#     "drafo-dummy21./subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/dummy-rg/providers/Microsoft.Storage/storageAccounts/dummy1sa" = {
#       "storage_id": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/dummy-rg/providers/Microsoft.Storage/storageAccounts/dummy1sa",
#       "vm_name": "drafo-dummy21"
#     }
#     "drafo-dummy21./subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/dummy-rg/providers/Microsoft.Storage/storageAccounts/dummy2sa" = {
#       "storage_id": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/dummy-rg/providers/Microsoft.Storage/storageAccounts/dummy2sa",
#       "vm_name": "drafo-dummy21"
#     }
# }
resource "azurerm_role_assignment" "sql_shared_hybrid_worker_backup_storage_key_operator" {
  for_each             = { for item in local.sql_shared_db_restore_rbac_map : "${item.vm_name}.${item.storage_id}" => item }
  scope                = each.value.storage_id
  role_definition_name = "Storage Account Key Operator Service Role"
  principal_id         = module.sql_shared.identity["${each.value.vm_name}"].principal_id
}

resource "azurerm_role_assignment" "sql2_hybrid_worker_backup_storage_key_operator" {
  for_each             = { for item in local.sql2_db_restore_rbac_map : "${item.vm_name}.${item.storage_id}" => item }
  scope                = each.value.storage_id
  role_definition_name = "Storage Account Key Operator Service Role"
  principal_id         = module.sql2.identity["${each.value.vm_name}"].principal_id
}

resource "azurerm_role_assignment" "sql4_hybrid_worker_backup_storage_key_operator" {
  for_each             = { for item in local.sql4_db_restore_rbac_map : "${item.vm_name}.${item.storage_id}" => item }
  scope                = each.value.storage_id
  role_definition_name = "Storage Account Key Operator Service Role"
  principal_id         = module.sql4.identity["${each.value.vm_name}"].principal_id
}

resource "azurerm_role_assignment" "sql5_hybrid_worker_backup_storage_key_operator" {
  for_each             = { for item in local.sql5_db_restore_rbac_map : "${item.vm_name}.${item.storage_id}" => item }
  scope                = each.value.storage_id
  role_definition_name = "Storage Account Key Operator Service Role"
  principal_id         = module.sql5.identity["${each.value.vm_name}"].principal_id
}

resource "azurerm_role_assignment" "sql6_hybrid_worker_backup_storage_key_operator" {
  for_each             = { for item in local.sql6_db_restore_rbac_map : "${item.vm_name}.${item.storage_id}" => item }
  scope                = each.value.storage_id
  role_definition_name = "Storage Account Key Operator Service Role"
  principal_id         = module.sql6.identity["${each.value.vm_name}"].principal_id
}

resource "azurerm_role_assignment" "sql7_hybrid_worker_backup_storage_key_operator" {
  for_each             = { for item in local.sql7_db_restore_rbac_map : "${item.vm_name}.${item.storage_id}" => item }
  scope                = each.value.storage_id
  role_definition_name = "Storage Account Key Operator Service Role"
  principal_id         = module.sql7.identity["${each.value.vm_name}"].principal_id
}

resource "azurerm_role_assignment" "sql8_hybrid_worker_backup_storage_key_operator" {
  for_each             = { for item in local.sql8_db_restore_rbac_map : "${item.vm_name}.${item.storage_id}" => item }
  scope                = each.value.storage_id
  role_definition_name = "Storage Account Key Operator Service Role"
  principal_id         = module.sql8.identity["${each.value.vm_name}"].principal_id
}