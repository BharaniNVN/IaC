resource "azurerm_resource_group" "this" {
  name     = "${local.deprecated_prefix}-rg"
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
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
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
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
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
  resource_group_resource          = azurerm_resource_group.this
  log_analytics_workspace_resource = azurerm_log_analytics_workspace.this
  retention_in_days                = 30

  tags = local.tags
}

module "application_insights_mobileapi" {
  source = "../../../modules/terraform/application_insights"

  name                             = format("%s-mobileapi-appins", local.prefix)
  resource_group_resource          = azurerm_resource_group.this
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

module "application_insights_gc" {
  source = "../../../modules/terraform/application_insights"

  name                             = format("%s-gc-appins", local.prefix)
  resource_group_resource          = azurerm_resource_group.this
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

  api_key_name             = format("%s-mail", local.deprecated_prefix)
  key_vault_id             = azurerm_key_vault_access_policy.terraform_all_managed.key_vault_id
  management_api_key_value = data.terraform_remote_state.prod_shared.outputs.sendgrid_management_api_key
  secret_name              = format("%sSendGridMailApiKey", local.prefix)
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
  key_vault_id = data.terraform_remote_state.prod_shared.outputs.initial_key_vault_id
  tenant_id    = azurerm_user_assigned_identity.key_vault_certificates.tenant_id
  object_id    = azurerm_user_assigned_identity.key_vault_certificates.principal_id

  secret_permissions = [
    "Get",
    "List",
  ]
}

module "machine_key" {
  source = "../../../modules/terraform/machine_key_generator"

  key_vault_id = azurerm_key_vault_access_policy.terraform_all_managed.key_vault_id
}
