module "sql_shared" {
  source = "../../../../modules/terraform/sql_server"

  resource_group_resource                 = azurerm_resource_group.this
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-sqlsaz01"]
  availability_set_suffix                 = "-sqlsaz-av"
  boot_diagnostics_storage_account_suffix = "sqlsazmxhhpdiag"
  subnet_resource                         = azurerm_subnet.internal
  dns_servers                             = data.terraform_remote_state.nonprod_shared.outputs.domain_specifics.dns_servers
  vm_starting_ip                          = 10
  vm_size                                 = "Standard_D4s_v3"
  data_disk = [
    { "name" = "db", "type" = "Premium_LRS", "size" = 500, "lun" = 0, "caching" = "ReadOnly" },
    { "name" = "logs", "type" = "StandardSSD_LRS", "size" = 200, "lun" = 1, "caching" = "None" },
    { "name" = "temp", "type" = "Premium_LRS", "size" = 200, "lun" = 2, "caching" = "ReadOnly" },
    { "name" = "backup", "type" = "Standard_LRS", "size" = 500, "lun" = 3, "caching" = "None" },
  ]
  user_assigned_identity_ids              = [data.terraform_remote_state.shared_afo.outputs.db_backups_uai_id]
  dsc_storage_container_resource          = data.terraform_remote_state.nonprod_shared.outputs.dsc_storage_container
  dsc_extension_version                   = var.dsc_extension_version
  admin_username                          = var.local_admin_user
  admin_password                          = var.local_admin_pswd
  domain_name                             = local.domain_name
  domain_join_account                     = data.terraform_remote_state.nonprod_shared.outputs.domain_join_credential.username
  domain_join_password                    = data.terraform_remote_state.nonprod_shared.outputs.domain_join_credential.password
  join_ou                                 = "OU=MsSql,OU=Azure,OU=Servers,${local.domain_dn}"
  local_groups_members                    = { "Administrators" = formatlist("%s\\%s", local.domain_netbios_name, ["sqladmin"]) }
  sql_sa_password                         = var.sql_sa_pswd
  sql_service_user                        = format("%s\\\\%s", local.domain_netbios_name, var.sql_service_user)
  sql_service_pass                        = var.sql_service_pswd
  sql_agent_user                          = format("%s\\\\%s", local.domain_netbios_name, var.sql_agent_user)
  sql_agent_pass                          = var.sql_agent_pswd
  smtp_user                               = module.sendgrid_apikey.sendgrid_api_key_username
  smtp_pswd                               = module.sendgrid_apikey.sendgrid_api_key_value
  smtp_server                             = data.terraform_remote_state.nonprod_shared.outputs.sendgrid_servername
  from_address                            = "HHPOPS@mxhhpdev.com"
  replyto_address                         = "HHPOPS@mxhhpdev.com"
  smtp_port                               = "587"
  sql_admin_accounts                      = ["sqladmin"]
  sql_iso_path                            = var.sql_iso_path
  ssms_install_path                       = var.ssms_install_path
  sql_port                                = 1593
  deployment_agent_account                = format("%s\\\\%s", local.domain_netbios_name, var.deployment_agent_user)
  deployment_agent_password               = var.deployment_agent_pswd
  nxlog_conf                              = var.nxlog_conf
  nxlog_pem                               = var.nxlog_pem
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.this
  azure_devops_extension_version          = var.azure_devops_extension_version
  azure_devops_account                    = var.azure_devops_account
  azure_devops_project                    = var.azure_devops_project
  azure_devops_deployment_group           = var.azure_devops_deployment_group
  azure_devops_agent_tags                 = "DB, MsSql, Shared"
  azure_devops_pat_token                  = var.azure_devops_pat_token
  dependency_agent_extension_version      = var.dependency_agent_extension_version
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version

  tags = merge(
    local.tags,
    {
      "logicalEnvironment" = "shared"
      "backend"            = "true"
    },
  )

  module_depends_on = [module.blob, module.file]
}
