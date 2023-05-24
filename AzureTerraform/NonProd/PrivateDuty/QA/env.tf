module "app" {
  source = "../../../../modules/terraform/app_server"

  resource_group_resource                 = azurerm_resource_group.this
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-appaz01"]
  availability_set_suffix                 = "-appaz-av"
  boot_diagnostics_storage_account_suffix = "appazmxhhpdiag"
  subnet_resource                         = azurerm_subnet.this
  dns_servers                             = data.terraform_remote_state.nonprod_shared.outputs.domain_specifics.dns_servers
  vm_starting_ip                          = 14
  vm_size                                 = "Standard_F4s_v2"
  image_sku                               = "2019-Datacenter"
  data_disk = [
    { "name" = "data", "type" = "StandardSSD_LRS", "size" = 128, "lun" = 0, "caching" = "ReadOnly" },
  ]
  dsc_storage_container_resource = data.terraform_remote_state.nonprod_shared.outputs.dsc_storage_container
  dsc_extension_version          = var.dsc_extension_version
  admin_username                 = var.local_admin_user
  admin_password                 = var.local_admin_pswd
  domain_name                    = local.domain_name
  domain_join_account            = data.terraform_remote_state.nonprod_shared.outputs.domain_join_credential.username
  domain_join_password           = data.terraform_remote_state.nonprod_shared.outputs.domain_join_credential.password
  join_ou                        = "OU=APP,OU=Azure,OU=Servers,${local.domain_dn}"
  local_groups_members           = { "Administrators" = formatlist("%s\\%s", local.domain_netbios_name, var.local_administrators) }
  service_accounts               = formatlist("%s\\%s", local.domain_netbios_name, ["PD_QA_VCONNECT", "PD_QA_POLLER", "PD_QA_TELEPHONY"])
  folders_permissions = {
    format("%s\\%s", local.domain_netbios_name, "PD_QA_WEB2API") = { "Modify" = ["f:\\www"] },
  }
  file_shares = [
    { "name" = "www", "path" = "f:\\www", "changeaccess" = formatlist("%s\\%s", local.domain_netbios_name, "PD_QA_WEB2API") },
  ]
  nxlog_conf                              = var.nxlog_conf
  nxlog_pem                               = var.nxlog_pem
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.this
  azure_devops_extension_version          = var.azure_devops_extension_version
  azure_devops_account                    = var.azure_devops_account
  azure_devops_project                    = var.azure_devops_project
  azure_devops_deployment_group           = "US-Azure-EastUs2-PdQa-NonProd"
  azure_devops_agent_tags                 = "APP"
  azure_devops_pat_token                  = var.azure_devops_pat_token
  dependency_agent_extension_version      = var.dependency_agent_extension_version
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version

  tags = local.tags
}

module "web" {
  source = "../../../../modules/terraform/web_server"

  resource_group_resource                 = azurerm_resource_group.this
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-webaz01", "-webaz02"]
  availability_set_suffix                 = "-webaz-av"
  boot_diagnostics_storage_account_suffix = "webazmxhhpdiag"
  subnet_resource                         = azurerm_subnet.this
  dns_servers                             = data.terraform_remote_state.nonprod_shared.outputs.domain_specifics.dns_servers
  vm_starting_ip                          = 17
  vm_size                                 = "Standard_F4s_v2"
  image_sku                               = "2019-Datacenter"
  enable_internal_loadbalancer            = true
  lb_ip                                   = var.lb_ip
  lb_rules = [
    { "probe" = { "Tcp" = 80 }, "rule" = {} },
    { "probe" = { "Tcp" = 443 }, "rule" = {} },
  ]
  lb_load_distribution       = var.lb_load_distribution
  user_assigned_identity_ids = [azurerm_user_assigned_identity.key_vault_certificates.id]
  certificate_urls = [
    data.terraform_remote_state.nonprod_shared.outputs.certificates["mxhhpdev_com"],
  ]
  key_vault_extension_version    = var.key_vault_extension_version
  key_vault_msi_client_id        = azurerm_user_assigned_identity.key_vault_certificates.client_id
  dsc_storage_container_resource = data.terraform_remote_state.nonprod_shared.outputs.dsc_storage_container
  dsc_extension_version          = var.dsc_extension_version
  dsc_script_file_name           = "WebPD"
  admin_username                 = var.local_admin_user
  admin_password                 = var.local_admin_pswd
  domain_name                    = local.domain_name
  domain_join_account            = data.terraform_remote_state.nonprod_shared.outputs.domain_join_credential.username
  domain_join_password           = data.terraform_remote_state.nonprod_shared.outputs.domain_join_credential.password
  join_ou                        = "OU=WEB,OU=Azure,OU=Servers,${local.domain_dn}"
  local_groups_members           = { "Administrators" = formatlist("%s\\%s", local.domain_netbios_name, var.local_administrators) } # add PD_QA_WEB2API ???
  hosts_entries = [for i in [
    local.pipeline_variables_all_managed["apiFQDN"],
    local.pipeline_variables_all_managed["appFQDN"],
    local.pipeline_variables_all_managed["authFQDN"],
    local.pipeline_variables_all_managed["clickonceFQDN"],
    local.pipeline_variables_all_managed["idmApiFQDN"],
    local.pipeline_variables_all_managed["managementFQDN"],
    local.pipeline_variables_all_managed["mgmtinterfaceFQDN"],
    local.pipeline_variables_all_managed["telephonyApiFQDN"],
    local.pipeline_variables_all_managed["telephonyServiceFQDN"],
    local.pipeline_variables_all_managed["clickonceHistoricFQDN"],
    local.pipeline_variables_all_managed["clickonceRegressionFQDN"],
    local.pipeline_variables_all_managed["clickonceReleaseFQDN"],
  ] : { "name" = i, "ip" = "127.0.0.1" }]
  nxlog_conf                              = var.nxlog_conf
  nxlog_pem                               = var.nxlog_pem
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.this
  azure_devops_extension_version          = var.azure_devops_extension_version
  azure_devops_account                    = var.azure_devops_account
  azure_devops_project                    = var.azure_devops_project
  azure_devops_deployment_group           = "US-Azure-EastUs2-PdQa-NonProd"
  azure_devops_agent_tags                 = "WEB"
  azure_devops_pat_token                  = var.azure_devops_pat_token
  dependency_agent_extension_version      = var.dependency_agent_extension_version
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version

  tags = local.tags

  module_depends_on = [azurerm_key_vault_access_policy.key_vault_certificates]
}

module "sql" {
  source = "../../../../modules/terraform/sql_server"

  resource_group_resource                 = azurerm_resource_group.this
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-sqlaz01"]
  availability_set_suffix                 = "-sqlaz-av"
  boot_diagnostics_storage_account_suffix = "sqlazmxhhpdiag"
  subnet_resource                         = azurerm_subnet.this
  dns_servers                             = data.terraform_remote_state.nonprod_shared.outputs.domain_specifics.dns_servers
  vm_starting_ip                          = 10
  vm_size                                 = "Standard_D8s_v4"
  data_disk = [
    { "name" = "db", "type" = "Premium_LRS", "size" = 128, "lun" = 0, "caching" = "ReadOnly" },
    { "name" = "logs", "type" = "StandardSSD_LRS", "size" = 128, "lun" = 1, "caching" = "None" },
    { "name" = "temp", "type" = "Premium_LRS", "size" = 128, "lun" = 2, "caching" = "ReadOnly" },
    { "name" = "backup", "type" = "Standard_LRS", "size" = 128, "lun" = 3, "caching" = "None" },
  ]
  user_assigned_identity_ids     = [data.terraform_remote_state.privateduty_shared.outputs.db_backups_uai_id]
  dsc_storage_container_resource = data.terraform_remote_state.nonprod_shared.outputs.dsc_storage_container
  dsc_extension_version          = var.dsc_extension_version
  admin_username                 = var.local_admin_user
  admin_password                 = var.local_admin_pswd
  domain_name                    = local.domain_name
  domain_join_account            = data.terraform_remote_state.nonprod_shared.outputs.domain_join_credential.username
  domain_join_password           = data.terraform_remote_state.nonprod_shared.outputs.domain_join_credential.password
  join_ou                        = "OU=MsSql,OU=Azure,OU=Servers,${local.domain_dn}"
  local_groups_members           = { "Administrators" = formatlist("%s\\%s", local.domain_netbios_name, concat(var.local_administrators, ["SqlAdmin"])) }
  sql_admin_accounts             = ["sqladmin", var.ssrs_sql_server_user]
  sql_agent_user                 = format("%s\\\\%s", local.domain_netbios_name, var.sql_agent_user)
  sql_agent_pass                 = var.sql_agent_pswd
  sql_sa_password                = var.sql_sa_pswd
  sql_service_user               = format("%s\\\\%s", local.domain_netbios_name, var.sql_service_user)
  sql_service_pass               = var.sql_service_pswd
  sql_logins = [
    { "name" = format("%s\\PD_QA_VCONNECT", local.domain_netbios_name), "logintype" = "WindowsUser", "password" = "" },
    { "name" = format("%s\\PD_QA_POLLER", local.domain_netbios_name), "logintype" = "WindowsUser", "password" = "" },
    { "name" = format("%s\\PD_QA_TELEPHONY", local.domain_netbios_name), "logintype" = "WindowsUser", "password" = "" },
  ]
  sql_iso_path                            = var.sql_iso_path
  ssms_install_path                       = var.ssms_install_path
  sql_port                                = 1593
  nxlog_conf                              = var.nxlog_conf
  nxlog_pem                               = var.nxlog_pem
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.this
  deployment_agent_account                = format("%s\\\\%s", local.domain_netbios_name, var.deployment_agent_user)
  deployment_agent_password               = var.deployment_agent_pswd
  azure_devops_extension_version          = var.azure_devops_extension_version
  azure_devops_account                    = var.azure_devops_account
  azure_devops_project                    = var.azure_devops_project
  azure_devops_deployment_group           = "US-Azure-EastUs2-PdQa-NonProd"
  azure_devops_agent_tags                 = "DB, MsSql"
  azure_devops_pat_token                  = var.azure_devops_pat_token
  dependency_agent_extension_version      = var.dependency_agent_extension_version
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version

  tags = merge(
    local.tags,
    {
      "backend" = "true"
    },
  )
}

module "ssrs" {
  source = "../../../../modules/terraform/ssrs_server"

  resource_group_resource                 = azurerm_resource_group.this
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-ssrsaz01"]
  availability_set_suffix                 = "-ssrsaz-av"
  boot_diagnostics_storage_account_suffix = "ssrsazmxhhpdiag"
  subnet_resource                         = azurerm_subnet.this
  dns_servers                             = data.terraform_remote_state.nonprod_shared.outputs.domain_specifics.dns_servers
  vm_starting_ip                          = 12
  vm_size                                 = "Standard_F4s_v2"
  data_disk = [
    { "name" = "data", "type" = "StandardSSD_LRS", "size" = 128, "lun" = 0, "caching" = "ReadOnly" },
  ]
  user_assigned_identity_ids              = [azurerm_user_assigned_identity.key_vault_certificates.id]
  certificate_urls                        = [data.terraform_remote_state.nonprod_shared.outputs.certificates["mxhhpdev_com"]]
  key_vault_extension_version             = var.key_vault_extension_version
  key_vault_msi_client_id                 = azurerm_user_assigned_identity.key_vault_certificates.client_id
  dsc_storage_container_resource          = data.terraform_remote_state.nonprod_shared.outputs.dsc_storage_container
  dsc_extension_version                   = var.dsc_extension_version
  admin_username                          = var.local_admin_user
  admin_password                          = var.local_admin_pswd
  domain_name                             = local.domain_name
  domain_join_account                     = data.terraform_remote_state.nonprod_shared.outputs.domain_join_credential.username
  domain_join_password                    = data.terraform_remote_state.nonprod_shared.outputs.domain_join_credential.password
  join_ou                                 = "OU=MsSql,OU=Azure,OU=Servers,${local.domain_dn}"
  local_groups_members                    = { "Administrators" = formatlist("%s\\%s", local.domain_netbios_name, concat(var.local_administrators, [var.ssrs_sql_server_user])) }
  ssrs_database_server_name               = values(module.sql.name_with_fqdn_and_port)[0]
  ssrs_service_account                    = format("%s\\\\%s", local.domain_netbios_name, var.ssrs_service_account)
  ssrs_service_password                   = var.ssrs_service_password
  ssrs_sql_server_account                 = format("%s\\\\%s", local.domain_netbios_name, var.ssrs_sql_server_user)
  ssrs_sql_server_password                = var.ssrs_sql_server_pswd
  ssrs_report_server_reserved_url         = ["http://+:80", "https://+:443"]
  ssrs_reports_reserved_url               = ["http://+:80", "https://+:443"]
  ssrs_ssl_certificate_thumbprint         = data.azurerm_app_service_certificate_order.mxhhpdev_com.signed_certificate_thumbprint
  nxlog_conf                              = var.nxlog_conf
  nxlog_pem                               = var.nxlog_pem
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.this
  azure_devops_extension_version          = var.azure_devops_extension_version
  azure_devops_account                    = var.azure_devops_account
  azure_devops_project                    = var.azure_devops_project
  azure_devops_deployment_group           = "US-Azure-EastUs2-PdQa-NonProd"
  azure_devops_agent_tags                 = "SSRS"
  azure_devops_pat_token                  = var.azure_devops_pat_token
  dependency_agent_extension_version      = var.dependency_agent_extension_version
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version

  tags = local.tags
}

module "build" {
  source = "../../../../modules/terraform/domain_member_server"

  resource_group_resource                 = azurerm_resource_group.this
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-bldaz01"]
  availability_set_suffix                 = "-bldaz-av"
  boot_diagnostics_storage_account_suffix = "bldazmxhhpdiag"
  subnet_resource                         = azurerm_subnet.this
  dns_servers                             = data.terraform_remote_state.nonprod_shared.outputs.domain_specifics.dns_servers
  vm_starting_ip                          = 20
  vm_size                                 = "Standard_D2s_v3"
  image_publisher                         = "microsoftvisualstudio"
  image_offer                             = "visualstudio2019"
  image_sku                               = "vs-2019-ent-ws2019"
  data_disk = [
    { "name" = "data", "type" = "Standard_LRS", "size" = 64, "lun" = 0, "caching" = "None" },
  ]
  dsc_storage_container_resource          = data.terraform_remote_state.nonprod_shared.outputs.dsc_storage_container
  dsc_extension_version                   = var.dsc_extension_version
  admin_username                          = var.local_admin_user
  admin_password                          = var.local_admin_pswd
  domain_name                             = local.domain_name
  domain_join_account                     = data.terraform_remote_state.nonprod_shared.outputs.domain_join_credential.username
  domain_join_password                    = data.terraform_remote_state.nonprod_shared.outputs.domain_join_credential.password
  join_ou                                 = "OU=APP,OU=Azure,OU=Servers,${local.domain_dn}"
  nxlog_conf                              = var.nxlog_conf
  nxlog_pem                               = var.nxlog_pem
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.this
  dependency_agent_extension_version      = var.dependency_agent_extension_version
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version

  tags = merge(
    local.tags,
    {
      "doNotShutdown" = "true"
    },
  )
}
