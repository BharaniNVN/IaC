resource "azurerm_resource_group" "shared_internal" {
  name     = "${local.prefix}-shared-internal-rg"
  location = var.location

  tags = merge(
    local.tags,
    {
      "logicalEnvironment" = "shared"
      "resource"           = "resource group"
    },
  )
}

module "sql_shared" {
  source = "../../../modules/terraform/sql_server_with_hybrid_worker"

  resource_group_resource                 = azurerm_resource_group.shared_internal
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-sqlsaz01"]
  availability_set_suffix                 = "-sqlsaz-av"
  boot_diagnostics_storage_account_suffix = "sqlsazmxhhpdiag"
  subnet_resource                         = local.internal_subnet
  dns_servers                             = local.internal_domain["dns_servers"]
  vm_starting_ip                          = 110
  vm_size                                 = "Standard_E16s_v3"
  data_disk = [
    { "name" = "db", "type" = "Premium_LRS", "size" = 5000, "lun" = 0, "caching" = "None" },
    { "name" = "logs", "type" = "Standard_LRS", "size" = 200, "lun" = 1, "caching" = "None" },
    { "name" = "temp", "type" = "Premium_LRS", "size" = 200, "lun" = 2, "caching" = "ReadOnly" },
    { "name" = "backup", "type" = "StandardSSD_LRS", "size" = 2000, "lun" = 3, "caching" = "None" },
  ]
  dsc_storage_container_resource = local.dsc_storage_container
  dsc_extension_version          = var.dsc_extension_version
  admin_username                 = var.local_admin_user
  admin_password                 = var.local_admin_pswd
  domain_name                    = local.internal_domain["name"]
  domain_join_account            = data.terraform_remote_state.dr_shared.outputs.internal_domain_join_credential.username
  domain_join_password           = data.terraform_remote_state.dr_shared.outputs.internal_domain_join_credential.password
  join_ou                        = "OU=MsSql,OU=Azure DR,OU=Azure,${local.internal_domain_dn}"
  local_groups_members           = { "Administrators" = formatlist("%s\\%s", local.internal_domain["netbiosname"], ["SQLADMIN"]) }
  sql_sa_password                = var.sql_sa_pswd
  sql_service_user               = format("%s\\\\%s", local.internal_domain["netbiosname"], var.sql_svc_usr)
  sql_service_pass               = var.sql_svc_pswd
  sql_agent_user                 = format("%s\\\\%s", local.internal_domain["netbiosname"], var.sql_agent_user)
  sql_agent_pass                 = var.sql_agent_pswd
  smtp_user                      = module.sendgrid_apikey.sendgrid_api_key_username
  smtp_pswd                      = module.sendgrid_apikey.sendgrid_api_key_value
  smtp_server                    = data.terraform_remote_state.prod_shared.outputs.sendgrid_servername
  from_address                   = "HHPDR@mxhhpprod.com"
  replyto_address                = "HHPDR@mxhhpprod.com"
  smtp_port                      = "587"
  sql_admin_accounts             = ["SQLADMIN"]
  sql_iso_path                   = var.sql_iso_path
  ssms_install_path              = var.ssms_install_path
  sql_port                       = 1593
  sql_logins = [
    { "name" = "CAWDMZ\\sqlread", "logintype" = "WindowsGroup", "password" = "" }
  ]
  deployment_agent_account                = format("%s\\\\%s", local.internal_domain["netbiosname"], var.deployment_agent_user)
  deployment_agent_password               = var.deployment_agent_pswd
  nxlog_conf                              = var.nxlog_conf
  nxlog_pem                               = var.nxlog_pem
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.this
  azure_devops_extension_version          = var.azure_devops_extension_version
  azure_devops_account                    = var.azure_devops_account
  azure_devops_project                    = var.azure_devops_project
  azure_devops_deployment_group           = "US-Azure-NorthCentral-US-DR"
  azure_devops_agent_tags                 = "DB, MsSql, Shared"
  azure_devops_pat_token                  = var.azure_devops_pat_token
  dependency_agent_extension_version      = var.dependency_agent_extension_version
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version
  create_system_assigned_identity         = true
  automation_account_resource = {
    id                  = module.automation.automation_account_id
    name                = module.automation.automation_account_name
    resource_group_name = module.automation.automation_account_resource_group_name
    endpoint            = module.automation.automation_account_endpoint
  }
  automation_account_credential_name = "${local.prefix}-localvmadmin-credential"

  tags = merge(
    local.tags,
    {
      "logicalEnvironment" = "shared"
      "backend"            = "true"
    },
  )
}
