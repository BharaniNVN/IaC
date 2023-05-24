locals {
  timezone = "America/New_York"
}

data "external" "start" {
  program = ["bash", "-c", "d=$(date --date='TZ=\"${local.timezone}\" 02:00 tomorrow' +'%Y-%m-%dT%I:%M:%SZ'); jq -n \"{\\\"date\\\": \\\"$d\\\"}\""]
}

data "external" "stop" {
  program = ["bash", "-c", "d=$(date --date='TZ=\"${local.timezone}\" 20:00 tomorrow' +'%Y-%m-%dT%I:%M:%SZ'); jq -n \"{\\\"date\\\": \\\"$d\\\"}\""]
}

locals {
  start_time = data.external.start.result.date
  stop_time  = data.external.stop.result.date
}

module "automation" {
  source = "../../../../modules/terraform/automation_scripts"

  application                      = var.application
  application_prefix               = var.application_prefix
  environment                      = var.environment
  environment_prefix               = var.environment_prefix
  resource_group_resource          = azurerm_resource_group.this
  run_as_account_username          = data.terraform_remote_state.nonprod_shared.outputs.vm_operator_credential.username
  run_as_account_password          = data.terraform_remote_state.nonprod_shared.outputs.vm_operator_credential.password
  timezone                         = local.timezone
  start_time                       = local.start_time
  stop_time                        = local.stop_time
  tag_stage1                       = "backend"
  tag_stage1_value                 = "true"
  tag_stage2                       = "application"
  tag_stage2_value                 = var.application
  tag_to_exclude                   = "doNotShutdown"
  tag_to_exclude_value             = "true"
  log_analytics_workspace_resource = azurerm_log_analytics_workspace.this

  permissions = {
    "Automation Job Operator" = [data.azuread_group.env_access_group.object_id]
  }

  tags = local.tags
}
