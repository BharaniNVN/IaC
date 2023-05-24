module "afo" {
  source = "../../../../modules/terraform/afo_server"

  resource_group_resource                 = azurerm_resource_group.this
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-afoaz01", "-afoaz02"]
  availability_set_suffix                 = "-afoaz-av"
  boot_diagnostics_storage_account_suffix = "afoazmxhhpdiag"
  subnet_resource                         = azurerm_subnet.dmz
  dns_servers                             = data.terraform_remote_state.nonprod_shared.outputs.domain_specifics.dns_servers
  vm_starting_ip                          = var.afo_lb_ip + 1
  vm_size                                 = "Standard_F4s_v2"
  user_assigned_identity_ids              = [azurerm_user_assigned_identity.key_vault_certificates.id]
  certificate_urls = [
    data.terraform_remote_state.nonprod_shared.outputs.certificates["mxhhpdev_com"],
    data.terraform_remote_state.nonprod_shared.outputs.certificates["sfsso_brightree_net"],
    data.terraform_remote_state.nonprod_shared.outputs.certificates["community_matrixcare_com"],
    data.terraform_remote_state.nonprod_shared.outputs.certificates["ehomecare_com"],
  ]
  key_vault_extension_version    = var.key_vault_extension_version
  key_vault_msi_client_id        = azurerm_user_assigned_identity.key_vault_certificates.client_id
  dsc_storage_container_resource = data.terraform_remote_state.nonprod_shared.outputs.dsc_storage_container
  dsc_extension_version          = var.dsc_extension_version
  admin_username                 = var.local_admin_user
  admin_password                 = var.local_admin_pswd
  domain_name                    = local.domain_name
  domain_join_account            = data.terraform_remote_state.nonprod_shared.outputs.domain_join_credential.username
  domain_join_password           = data.terraform_remote_state.nonprod_shared.outputs.domain_join_credential.password
  join_ou                        = "OU=AFO,OU=Azure,OU=Servers,${local.domain_dn}"
  local_groups_members = {
    "IIS_IUSRS"            = formatlist("%s\\%s", local.domain_netbios_name, [var.app_pool_account])
    "Remote Desktop Users" = formatlist("%s\\%s", local.domain_netbios_name, [var.nondbservers_rdp_users])
  }
  firewall_ports = [80, 443, 8001, 8501]
  folders_permissions = {
    "IIS_IUSRS" = { "Read" = ["C:\\BT\\API", "C:\\BT\\WEB", "C:\\AMS\\AMSRoot", "C:\\Applications\\Documents"], "FullControl" = ["C:\\Logs", "C:\\Temp"] },
  }
  dns_records = [
    { "name" = format("%s-secure1", local.prefix), "zone" = local.aad_domain_name, "ip" = cidrhost(azurerm_subnet.dmz.address_prefixes[0], var.afo_lb_ip + 1) },
    { "name" = format("%s-secure2", local.prefix), "zone" = local.aad_domain_name, "ip" = cidrhost(azurerm_subnet.dmz.address_prefixes[0], var.afo_lb_ip + 2) },
    { "name" = azurerm_redis_cache.redis.name, "zone" = format("privatelink%s", trimprefix(azurerm_redis_cache.redis.hostname, azurerm_redis_cache.redis.name)), "ip" = module.redis.private_ip_address },
  ]
  nxlog_conf                              = var.nxlog_conf
  nxlog_pem                               = var.nxlog_pem
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.this
  azure_devops_extension_version          = var.azure_devops_extension_version
  azure_devops_account                    = var.azure_devops_account
  azure_devops_project                    = var.azure_devops_project
  azure_devops_deployment_group           = var.azure_devops_deployment_group
  azure_devops_agent_tags                 = "AFO"
  azure_devops_pat_token                  = var.azure_devops_pat_token
  dependency_agent_extension_version      = var.dependency_agent_extension_version
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version

  tags = local.tags

  module_depends_on = [
    azurerm_key_vault_access_policy.key_vault_certificates,
    module.blob,
    module.file,
    module.redis,
  ]
}

module "app" {
  source = "../../../../modules/terraform/app_server"

  resource_group_resource                 = azurerm_resource_group.this
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-appaz01"]
  availability_set_suffix                 = "-appaz-av"
  boot_diagnostics_storage_account_suffix = "appazmxhhpdiag"
  subnet_resource                         = azurerm_subnet.internal
  dns_servers                             = data.terraform_remote_state.nonprod_shared.outputs.domain_specifics.dns_servers
  vm_starting_ip                          = 4
  vm_size                                 = "Standard_D4s_v3"
  dsc_storage_container_resource          = data.terraform_remote_state.nonprod_shared.outputs.dsc_storage_container
  dsc_extension_version                   = var.dsc_extension_version
  admin_username                          = var.local_admin_user
  admin_password                          = var.local_admin_pswd
  domain_name                             = local.domain_name
  domain_join_account                     = data.terraform_remote_state.nonprod_shared.outputs.domain_join_credential.username
  domain_join_password                    = data.terraform_remote_state.nonprod_shared.outputs.domain_join_credential.password
  join_ou                                 = "OU=APP,OU=Azure,OU=Servers,${local.domain_dn}"
  batch_job_accounts                      = formatlist("%s\\%s", local.domain_netbios_name, [var.service_account, var.ssis_service_account])
  service_accounts                        = formatlist("%s\\%s", local.domain_netbios_name, [var.service_account, var.hangfire_service_account])
  local_groups_members = {
    "Administrators"       = formatlist("%s\\%s", local.domain_netbios_name, [var.hangfire_service_account])
    "Remote Desktop Users" = formatlist("%s\\%s", local.domain_netbios_name, [var.nondbservers_rdp_users])
  }
  enable_sql_developer = true
  enable_ssis          = true
  enable_oracle_tools  = true
  folders_permissions = {
    format("%s\\%s", local.domain_netbios_name, var.hangfire_service_account) = { "Read" = ["C:\\Applications", "C:\\BT\\APP"], "FullControl" = ["C:\\CAW", "C:\\Logs", "C:\\Temp"] },
    format("%s\\%s", local.domain_netbios_name, var.ssis_service_account)     = { "Read" = ["C:\\Applications", "C:\\BT\\APP"], "FullControl" = ["C:\\Logs", "C:\\Temp"] },
    format("%s\\%s", local.domain_netbios_name, var.service_account)          = { "Read" = ["C:\\Applications", "C:\\BT\\APP"], "FullControl" = ["C:\\CAW", "C:\\Logs", "C:\\Temp"] },
    format("%s\\%s", local.domain_netbios_name, var.app_pool_account)         = { "FullControl" = ["C:\\CAW"] },
  }
  file_shares = [
    { "name" = "caw", "path" = "c:\\caw", "changeaccess" = formatlist("%s\\%s", local.domain_netbios_name, [var.app_pool_account, var.hangfire_service_account, var.service_account]) },
  ]
  nxlog_conf                              = var.nxlog_conf
  nxlog_pem                               = var.nxlog_pem
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.this
  azure_devops_extension_version          = var.azure_devops_extension_version
  azure_devops_account                    = var.azure_devops_account
  azure_devops_project                    = var.azure_devops_project
  azure_devops_deployment_group           = var.azure_devops_deployment_group
  azure_devops_agent_tags                 = "APP"
  azure_devops_pat_token                  = var.azure_devops_pat_token
  dependency_agent_extension_version      = var.dependency_agent_extension_version
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version

  tags = local.tags

  module_depends_on = [module.blob, module.file]
}

module "sql" {
  source = "../../../../modules/terraform/sql_server"

  resource_group_resource                 = azurerm_resource_group.this
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-sqlaz01"]
  availability_set_suffix                 = "-sqlaz-av"
  boot_diagnostics_storage_account_suffix = "sqlazmxhhpdiag"
  subnet_resource                         = azurerm_subnet.internal
  dns_servers                             = data.terraform_remote_state.nonprod_shared.outputs.domain_specifics.dns_servers
  vm_starting_ip                          = 6
  vm_size                                 = "Standard_D8s_v3"
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
  azure_devops_agent_tags                 = "DB, MsSql, Clinical"
  azure_devops_pat_token                  = var.azure_devops_pat_token
  dependency_agent_extension_version      = var.dependency_agent_extension_version
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version

  tags = merge(
    local.tags,
    {
      "backend" = "true"
    },
  )

  module_depends_on = [module.blob, module.file]
}

module "oracle" {
  source = "../../../../modules/terraform/oracle"

  resource_group_resource                 = azurerm_resource_group.this
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-oraaz01"]
  availability_set_suffix                 = "-oraaz-av"
  boot_diagnostics_storage_account_suffix = "oraazmxhhpdiag"
  subnet_resource                         = azurerm_subnet.internal
  dns_servers                             = data.terraform_remote_state.nonprod_shared.outputs.domain_specifics.dns_servers
  vm_starting_ip                          = 8
  vm_size                                 = "Standard_E4s_v3"
  data_disk = [
    { "name" = "db", "type" = "Premium_LRS", "size" = 1000, "lun" = 0, "caching" = "ReadOnly" },
    { "name" = "backup", "type" = "Standard_LRS", "size" = 1000, "lun" = 1, "caching" = "None" },
  ]
  user_assigned_identity_ids              = [data.terraform_remote_state.shared_afo.outputs.db_backups_uai_id]
  dsc_storage_container_resource          = data.terraform_remote_state.nonprod_shared.outputs.dsc_storage_container
  dsc_extension_version                   = var.dsc_extension_version
  admin_username                          = var.local_admin_user
  admin_password                          = var.local_admin_pswd
  domain_name                             = local.domain_name
  domain_join_account                     = data.terraform_remote_state.nonprod_shared.outputs.domain_join_credential.username
  domain_join_password                    = data.terraform_remote_state.nonprod_shared.outputs.domain_join_credential.password
  join_ou                                 = "OU=Oracle,OU=Azure,OU=Servers,${local.domain_dn}"
  local_groups_members                    = { "Administrators" = formatlist("%s\\%s", local.domain_netbios_name, ["OracleAdmins"]) }
  batch_job_accounts                      = formatlist("%s\\%s", local.domain_netbios_name, [var.oracle_backup_account])
  firewall_ports                          = [1521]
  oracle_service_user                     = format("%s\\\\%s", local.domain_netbios_name, var.oracle_service_user)
  oracle_service_pswd                     = var.oracle_service_pswd
  oracle_sys_pswd                         = var.oracle_sys_pswd
  oracle_global_db_name                   = format("%scaw", lower(var.environment_prefix))
  oracle_install_files                    = var.oracle_install_files
  oracle_product_name                     = var.oracle_product_name
  oracle_product_version                  = var.oracle_product_version
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
  azure_devops_agent_tags                 = "DB, Oracle"
  azure_devops_pat_token                  = var.azure_devops_pat_token
  dependency_agent_extension_version      = var.dependency_agent_extension_version
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version

  tags = merge(
    local.tags,
    {
      "backend" = "true"
    },
  )

  module_depends_on = [module.blob, module.file]
}
