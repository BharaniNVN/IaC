module "automation" {
  source = "../../../modules/terraform/automation_scripts"

  application                      = var.application
  application_prefix               = var.application_prefix
  environment                      = var.environment
  environment_prefix               = var.environment_prefix
  resource_group_resource          = azurerm_resource_group.resources
  location                         = var.location
  run_as_account_username          = data.terraform_remote_state.prod_shared.outputs.vm_operator_credential.username
  run_as_account_password          = data.terraform_remote_state.prod_shared.outputs.vm_operator_credential.password
  sql_sa_password                  = var.sql_sa_pswd
  local_admin_user                 = var.local_admin_user
  local_admin_pswd                 = var.local_admin_pswd
  tag_stage1                       = "backend"
  tag_stage1_value                 = "true"
  tag_stage2                       = "application"
  tag_stage2_value                 = var.application
  tag_to_exclude                   = "doNotShutdown"
  tag_to_exclude_value             = "true"
  log_analytics_workspace_resource = azurerm_log_analytics_workspace.this
  tags                             = local.tags
}
