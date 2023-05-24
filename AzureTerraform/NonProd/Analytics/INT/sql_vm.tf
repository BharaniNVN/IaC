module "sql" {
  source = "../../../../modules/terraform/sql_server"

  resource_group_resource                 = azurerm_resource_group.analytics
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-sql"]
  subnet_resource                         = azurerm_subnet.analytics
  dns_servers                             = data.terraform_remote_state.nonprod_shared.outputs.domain_specifics_old.dns_servers
  boot_diagnostics_storage_account_suffix = "bootsql"
  vm_starting_ip                          = 5
  vm_size                                 = "Standard_E4s_v3"
  os_managed_disk_type                    = "Standard_LRS"
  data_disk = [
    { "name" = "db", "type" = "Standard_LRS", "size" = 500, "lun" = 10, "caching" = "None" },
    { "name" = "logs", "type" = "Standard_LRS", "size" = 500, "lun" = 11, "caching" = "None" },
    { "name" = "temp", "type" = "Standard_LRS", "size" = 500, "lun" = 12, "caching" = "None" },
    { "name" = "backup", "type" = "Standard_LRS", "size" = 500, "lun" = 13, "caching" = "None" },
  ]
  dsc_storage_container_resource = data.terraform_remote_state.nonprod_shared.outputs.dsc_storage_container
  dsc_extension_version          = var.dsc_extension_version
  admin_username                 = var.local_admin_user
  admin_password                 = var.local_admin_pswd
  domain_name                    = data.terraform_remote_state.nonprod_shared.outputs.domain_specifics_old.name
  domain_join_account            = data.terraform_remote_state.nonprod_shared.outputs.domain_join_credential.username
  domain_join_password           = data.terraform_remote_state.nonprod_shared.outputs.domain_join_credential.password
  join_ou                        = "OU=MsSql,OU=Azure,OU=Servers,${local.domain_dn}"
  sql_service_user               = var.sql_svc_usr
  sql_service_pass               = var.sql_svc_pswd
  sql_agent_user                 = var.sql_agent_user
  sql_agent_pass                 = var.sql_agent_pswd
  sql_sa_password                = var.sql_sa_pswd
  smtp_user                      = data.terraform_remote_state.analytics_shared.outputs.sendgrid_apikey_username
  smtp_pswd                      = data.terraform_remote_state.analytics_shared.outputs.sendgrid_apikey_pswd
  smtp_server                    = data.terraform_remote_state.nonprod_shared.outputs.sendgrid_servername
  from_address                   = "HHPOPS@mxhhpdev.com"
  replyto_address                = "HHPOPS@mxhhpdev.com"
  smtp_port                      = "587"
  sql_logins = [
    { "name" = "mxhhpdev\\sqlserverservice", "logintype" = "WindowsUser", "password" = "" },
    { "name" = "mxhhpdev\\sqladmins", "logintype" = "WindowsGroup", "password" = "" },
    { "name" = "adfuser", "logintype" = "SqlLogin", "password" = var.sql_login_adfuser_pswd },
  ]
  deployment_agent_account                = var.deployment_agent_user
  deployment_agent_password               = var.deployment_agent_pswd
  install_myanalytics_software_pack       = true
  integration_runtime_key                 = azurerm_template_deployment.ir.outputs["irkey"]
  sql_admin_accounts                      = ["sqladmins"]
  sql_iso_path                            = var.sql_iso_path
  ssms_install_path                       = var.ssms_install_path
  sql_port                                = 1593
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = data.terraform_remote_state.nonprod_shared.outputs.log_analytics
  azure_devops_extension_version          = var.azure_devops_extension_version
  azure_devops_account                    = var.azure_devops_account
  azure_devops_project                    = var.azure_devops_project
  azure_devops_deployment_group           = "US-Azure-EastUs2-Analytics-NonProd"
  azure_devops_agent_tags                 = "DB, MsSql, ssis, ${var.environment}"
  azure_devops_pat_token                  = var.azure_devops_pat_token
  dependency_agent_extension_version      = var.dependency_agent_extension_version
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version
  nxlog_conf                              = var.nxlog_conf
  nxlog_pem                               = var.nxlog_pem

  tags = merge(
    local.tags,
    {
      "backend" = "true"
    },
  )
}

