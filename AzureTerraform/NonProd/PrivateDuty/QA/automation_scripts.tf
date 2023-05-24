module "automation" {
  source = "../../../../modules/terraform/automation_scripts"

  application             = var.application
  application_prefix      = var.application_prefix
  environment             = var.environment
  environment_prefix      = var.environment_prefix
  resource_group_resource = azurerm_resource_group.this
  run_as_account_username = data.terraform_remote_state.nonprod_shared.outputs.vm_operator_credential.username
  run_as_account_password = data.terraform_remote_state.nonprod_shared.outputs.vm_operator_credential.password
  timezone                = "America/New_York"
  # start_time                       = "2021-09-03T07:00:00-04:00"
  # stop_time                        = "2021-09-03T23:00:00-04:00"
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
