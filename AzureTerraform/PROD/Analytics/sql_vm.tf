module "sql" {
  source = "../../../modules/terraform/sql_server"

  resource_group_resource = azurerm_resource_group.analytics
  resource_prefix         = local.deprecated_prefix
  virtual_machine_suffix  = ["-sql"]
  subnet_resource         = azurerm_subnet.analytics
  dns_servers             = data.terraform_remote_state.prod_shared.outputs.internal_dns_servers
  vm_starting_ip          = 5
  vm_size                 = "Standard_E4s_v3"
  os_managed_disk_type    = "Standard_LRS" # Needs to be changed to "StandardSSD_LRS" due to mainteinance window
  data_disk = [
    { "name" = "db", "type" = "Standard_LRS", "size" = 4095, "lun" = 10, "caching" = "None" },
    { "name" = "logs", "type" = "Standard_LRS", "size" = 2000, "lun" = 11, "caching" = "None" },
    { "name" = "temp", "type" = "Standard_LRS", "size" = 500, "lun" = 12, "caching" = "None" },
    { "name" = "backup", "type" = "Standard_LRS", "size" = 2000, "lun" = 13, "caching" = "None" },
  ]
  dsc_storage_container_resource = data.terraform_remote_state.prod_shared.outputs.dsc_storage_container
  dsc_extension_version          = var.dsc_extension_version
  admin_username                 = var.local_admin_user
  admin_password                 = var.local_admin_pswd
  domain_name                    = var.internal_domain_name
  domain_join_account            = var.internal_domain_join_user
  domain_join_password           = var.internal_domain_join_pswd
  join_ou                        = "OU=MsSql,OU=Azure Prod,OU=Azure,${local.internal_domain_dn}"
  sql_service_user               = var.sql_svc_usr
  sql_service_pass               = var.sql_svc_pswd
  sql_agent_user                 = var.sql_agent_user
  sql_agent_pass                 = var.sql_agent_pswd
  sql_sa_password                = var.sql_sa_pswd
  smtp_user                      = module.sendgrid_apikey.sendgrid_api_key_username
  smtp_pswd                      = module.sendgrid_apikey.sendgrid_api_key_value
  smtp_server                    = data.terraform_remote_state.prod_shared.outputs.sendgrid_servername
  from_address                   = "HHPOPS@mxhhpprod.com"
  replyto_address                = "HHPOPS@mxhhpprod.com"
  smtp_port                      = "587"
  sql_logins = [
    { "name" = "CAWPROD\\sqlserverservice", "logintype" = "WindowsUser", "password" = "" },
    { "name" = "CAWPROD\\sqladmin", "logintype" = "WindowsGroup", "password" = "" },
    { "name" = "adfuser", "logintype" = "SqlLogin", "password" = var.sql_login_adfuser_pswd },
  ]
  deployment_agent_account                = var.deployment_agent_user
  deployment_agent_password               = var.deployment_agent_pswd
  install_myanalytics_software_pack       = true
  integration_runtime_key                 = azurerm_template_deployment.ir.outputs["irkey"]
  sql_admin_accounts                      = ["SQLADMIN"]
  sql_iso_path                            = var.sql_iso_path
  ssms_install_path                       = var.ssms_install_path
  sql_port                                = 1593
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = data.terraform_remote_state.prod_shared.outputs.log_analytics
  azure_devops_extension_version          = var.azure_devops_extension_version
  azure_devops_account                    = var.azure_devops_account
  azure_devops_project                    = var.azure_devops_project
  azure_devops_deployment_group           = "US-Azure-NorthCentral-Analytics-Prod"
  azure_devops_agent_tags                 = "DB, MsSql"
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
