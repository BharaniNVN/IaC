locals {
  resource_group_name = var.resource_group_name != "" && (var.resource_group_name != var.resource_group_resource["name"] || local.location != var.resource_group_resource["location"]) ? azurerm_resource_group.this[0].name : var.resource_group_resource["name"]
  location            = coalesce(var.location, var.resource_group_resource["location"])
  permissions         = toset(flatten([for k, v in var.permissions : [for i in v : format("%s%s%s", k, local.separator, i)]]))
  prefix              = lower(format("%s%s", var.environment_prefix, var.application_prefix))
  separator           = "_"
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "this" {
  count = var.resource_group_name != "" && (var.resource_group_name != var.resource_group_resource["name"] || local.location != var.resource_group_resource["location"]) ? 1 : 0

  name     = var.resource_group_name
  location = local.location

  tags = merge(
    var.tags,
    {
      "resource" = "resource group"
    },
  )
}

resource "azurerm_automation_account" "this" {
  name                = "${local.prefix}-automation-account"
  location            = local.location
  resource_group_name = local.resource_group_name
  sku_name            = "Basic"

  tags = merge(
    var.tags,
    {
      "resource" = "automation account"
    },
  )
}

resource "azurerm_role_assignment" "this" {
  for_each = local.permissions

  scope                = azurerm_automation_account.this.id
  role_definition_name = split(local.separator, each.value)[0]
  principal_id         = split(local.separator, each.value)[1]
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.log_analytics_workspace_resource != null ? 1 : 0

  name                       = "SendAllLogsExcludingDscToLogAnalytics"
  target_resource_id         = azurerm_automation_account.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_resource["id"]

  dynamic "log" {
    for_each = {
      "AuditEvent"    = true,
      "DscNodeStatus" = false,
      "JobLogs"       = true,
      "JobStreams"    = true,
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
    enabled  = false

    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_automation_credential" "this" {
  name                    = "${local.prefix}-credential"
  resource_group_name     = local.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  username                = coalesce(var.run_as_account_username, data.azurerm_client_config.current.client_id)
  password                = var.run_as_account_password
  description             = "Automation account credential"
}

resource "azurerm_automation_credential" "sqlsa" {
  name                    = "${local.prefix}-sqlsa-credential"
  resource_group_name     = local.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  username                = "sa"
  password                = var.sql_sa_password
  description             = "SA credential for automatic DB restores on SQL servers"
}

resource "azurerm_automation_credential" "local_vm_admin" {
  name                    = "${local.prefix}-localvmadmin-credential"
  resource_group_name     = local.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  username                = var.local_admin_user
  password                = var.local_admin_pswd
  description             = "Local VM admin credential"
}

resource "azurerm_automation_runbook" "start_servers" {
  name                    = "${local.prefix}-start-servers"
  resource_group_name     = local.resource_group_name
  location                = local.location
  automation_account_name = azurerm_automation_account.this.name
  runbook_type            = "PowerShell"
  log_progress            = "true"
  log_verbose             = "true"

  content = templatefile("${path.module}/scripts/start.ps1",
    {
      SubscriptionID      = data.azurerm_client_config.current.subscription_id
      TenantID            = data.azurerm_client_config.current.tenant_id
      Environment         = var.environment
      VMprefix            = local.prefix
      DoNotShutdown       = var.tag_to_exclude
      DoNotShutdown_value = var.tag_to_exclude_value
      tag_stage1          = var.tag_stage1
      tag_stage1_value    = var.tag_stage1_value
      tag_stage2          = var.tag_stage2
      tag_stage2_value    = var.tag_stage2_value
      credentials         = azurerm_automation_credential.this.name
    }
  )

  tags = merge(
    var.tags,
    {
      "resource" = "automation runbook"
    },
  )
}

resource "azurerm_automation_runbook" "stop_servers" {
  name                    = "${local.prefix}-stop-servers"
  resource_group_name     = local.resource_group_name
  location                = local.location
  automation_account_name = azurerm_automation_account.this.name
  runbook_type            = "PowerShell"
  log_progress            = "true"
  log_verbose             = "true"

  content = templatefile("${path.module}/scripts/stop.ps1",
    {
      SubscriptionID      = data.azurerm_client_config.current.subscription_id
      TenantID            = data.azurerm_client_config.current.tenant_id
      Environment         = var.environment
      VMprefix            = local.prefix
      DoNotShutdown       = var.tag_to_exclude
      DoNotShutdown_value = var.tag_to_exclude_value
      credentials         = azurerm_automation_credential.this.name
    }
  )

  tags = merge(
    var.tags,
    {
      "resource" = "automation runbook"
    },
  )
}

resource "azurerm_automation_runbook" "sql_db_restore" {
  name                    = "${local.prefix}-sql-db-restore"
  resource_group_name     = local.resource_group_name
  location                = local.location
  automation_account_name = azurerm_automation_account.this.name
  runbook_type            = "PowerShell"
  log_progress            = "true"
  log_verbose             = "true"

  content = file("${path.module}/scripts/sql_restore.ps1")

  tags = merge(
    var.tags,
    {
      "resource" = "automation runbook"
    },
  )
}

resource "azurerm_automation_schedule" "start_servers" {
  count = var.start_time != "" ? 1 : 0

  name                    = "${local.prefix}-start"
  resource_group_name     = local.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  frequency               = "Week"
  description             = format("Schedule for starting VMs for '%s' product in %s environment", coalesce(var.application, "Undefined"), var.environment)
  start_time              = var.start_time
  timezone                = var.timezone
  week_days               = var.start_week_days
}

resource "azurerm_automation_schedule" "stop_servers" {
  count = var.stop_time != "" ? 1 : 0

  name                    = "${local.prefix}-stop"
  resource_group_name     = local.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  frequency               = "Week"
  description             = format("Schedule for stopping VMs for '%s' in %s environment", coalesce(var.application, "Undefined"), var.environment)
  start_time              = var.stop_time
  timezone                = var.timezone
  week_days               = var.stop_week_days
}

resource "azurerm_automation_job_schedule" "start_servers" {
  count = var.start_time != "" ? 1 : 0

  resource_group_name     = local.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  runbook_name            = azurerm_automation_runbook.start_servers.name
  schedule_name           = azurerm_automation_schedule.start_servers[0].name
}

resource "azurerm_automation_job_schedule" "stop_servers" {
  count = var.stop_time != "" ? 1 : 0

  resource_group_name     = local.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  runbook_name            = azurerm_automation_runbook.stop_servers.name
  schedule_name           = azurerm_automation_schedule.stop_servers[0].name
}
