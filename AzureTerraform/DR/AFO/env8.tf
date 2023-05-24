resource "azurerm_resource_group" "env8" {
  name     = "${local.prefix}-env8-rg"
  location = var.location

  tags = merge(
    local.tags,
    {
      "logicalEnvironment" = "DR8"
      "resource"           = "resource group"
    },
  )
}

module "afo8" {
  source = "../../../modules/terraform/afo_server"

  resource_group_resource                 = azurerm_resource_group.env8
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-afoaz81", "-afoaz82"]
  availability_set_suffix                 = "-afoaz8-av"
  boot_diagnostics_storage_account_suffix = "afoaz8mxhhpdiag"
  subnet_resource                         = local.dmz_subnet
  dns_servers                             = local.dmz_domain["dns_servers"]
  vm_starting_ip                          = var.afo8_vm_starting_ip
  vm_size                                 = "Standard_F16s"
  user_assigned_identity_ids              = [azurerm_user_assigned_identity.key_vault_certificates.id]
  certificate_urls = [
    local.cert_careanyware,
    local.cert_community_matrixcare_com,
  ]
  key_vault_extension_version    = var.key_vault_extension_version
  key_vault_msi_client_id        = azurerm_user_assigned_identity.key_vault_certificates.client_id
  dsc_storage_container_resource = local.dsc_storage_container
  dsc_extension_version          = var.dsc_extension_version
  admin_username                 = var.local_admin_user
  admin_password                 = var.local_admin_pswd
  domain_name                    = local.dmz_domain["name"]
  domain_join_account            = data.terraform_remote_state.dr_shared.outputs.dmz_domain_join_credential.username
  domain_join_password           = data.terraform_remote_state.dr_shared.outputs.dmz_domain_join_credential.password
  join_ou                        = "OU=Web,OU=Azure DR,OU=Azure,${local.dmz_domain_dn}"
  local_groups_members           = { "IIS_IUSRS" = formatlist("%s\\%s", local.dmz_domain["netbiosname"], [var.app_pool_account]) }
  firewall_ports                 = [80, 443, 8001, 8501]
  folders_permissions = {
    "IIS_IUSRS" = { "Read" = ["C:\\BT\\API", "C:\\BT\\WEB", "C:\\AMS\\AMSRoot", "C:\\Applications\\Documents"], "FullControl" = ["C:\\Logs", "C:\\Temp"] },
  }
  hosts_entries                           = local.hosts_entries
  nxlog_conf                              = var.nxlog_conf
  nxlog_pem                               = var.nxlog_pem
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.this
  azure_devops_extension_version          = var.azure_devops_extension_version
  azure_devops_account                    = var.azure_devops_account
  azure_devops_project                    = var.azure_devops_project
  azure_devops_deployment_group           = "US-Azure-NorthCentral-US-DR"
  azure_devops_agent_tags                 = "AFO, DR8"
  azure_devops_pat_token                  = var.azure_devops_pat_token
  dependency_agent_extension_version      = var.dependency_agent_extension_version
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version

  tags = merge(
    local.tags,
    {
      "logicalEnvironment" = "DR8"
    },
  )

  module_depends_on = [
    azurerm_key_vault_access_policy.key_vault_certificates,
    module.blob,
    module.file,
    module.redis,
  ]
}

module "app8" {
  source = "../../../modules/terraform/app_server"

  resource_group_resource                 = azurerm_resource_group.env8
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-appaz81"]
  availability_set_suffix                 = "-appaz8-av"
  boot_diagnostics_storage_account_suffix = "appaz8mxhhpdiag"
  subnet_resource                         = local.internal_subnet
  dns_servers                             = local.internal_domain["dns_servers"]
  vm_starting_ip                          = 40
  vm_size                                 = "Standard_D4s_v3"
  dsc_storage_container_resource          = local.dsc_storage_container
  dsc_extension_version                   = var.dsc_extension_version
  admin_username                          = var.local_admin_user
  admin_password                          = var.local_admin_pswd
  domain_name                             = local.internal_domain["name"]
  domain_join_account                     = data.terraform_remote_state.dr_shared.outputs.internal_domain_join_credential.username
  domain_join_password                    = data.terraform_remote_state.dr_shared.outputs.internal_domain_join_credential.password
  join_ou                                 = "OU=APP,OU=Azure DR,OU=Azure,${local.internal_domain_dn}"
  batch_job_accounts                      = formatlist("%s\\%s", local.dmz_domain["netbiosname"], [var.service_account, var.ssis_service_account])
  service_accounts                        = formatlist("%s\\%s", local.dmz_domain["netbiosname"], [var.service_account, var.hangfire_service_account])
  local_groups_members                    = { "Administrators" = formatlist("%s\\%s", local.dmz_domain["netbiosname"], [var.hangfire_service_account]) }
  enable_sql_developer                    = true
  enable_ssis                             = true
  enable_oracle_tools                     = true
  folders_permissions = {
    format("%s\\%s", local.dmz_domain["netbiosname"], var.hangfire_service_account) = { "Read" = ["C:\\Applications", "C:\\BT\\APP"], "FullControl" = ["C:\\CAW", "C:\\Logs", "C:\\Temp"] },
    format("%s\\%s", local.dmz_domain["netbiosname"], var.ssis_service_account)     = { "Read" = ["C:\\Applications", "C:\\BT\\APP"], "FullControl" = ["C:\\Logs", "C:\\Temp"] },
    format("%s\\%s", local.dmz_domain["netbiosname"], var.service_account)          = { "Read" = ["C:\\Applications", "C:\\BT\\APP"], "FullControl" = ["C:\\CAW", "C:\\Logs", "C:\\Temp"] },
    format("%s\\%s", local.dmz_domain["netbiosname"], var.app_pool_account)         = { "FullControl" = ["C:\\CAW"] },
  }
  file_shares = [
    { "name" = "caw", "path" = "c:\\caw", "changeaccess" = formatlist("%s\\%s", local.dmz_domain["netbiosname"], [var.app_pool_account, var.hangfire_service_account, var.service_account]) },
  ]
  hosts_entries                           = local.hosts_entries
  nxlog_conf                              = var.nxlog_conf
  nxlog_pem                               = var.nxlog_pem
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.this
  azure_devops_extension_version          = var.azure_devops_extension_version
  azure_devops_account                    = var.azure_devops_account
  azure_devops_project                    = var.azure_devops_project
  azure_devops_deployment_group           = "US-Azure-NorthCentral-US-DR"
  azure_devops_agent_tags                 = "APP, DR8"
  azure_devops_pat_token                  = var.azure_devops_pat_token
  dependency_agent_extension_version      = var.dependency_agent_extension_version
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version

  tags = merge(
    local.tags,
    {
      "logicalEnvironment" = "DR8"
    },
  )
}

module "sql8" {
  source = "../../../modules/terraform/sql_server_with_hybrid_worker"

  resource_group_resource                 = azurerm_resource_group.env8
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-sqlaz81"]
  availability_set_suffix                 = "-sqlaz8-av"
  boot_diagnostics_storage_account_suffix = "sqlaz8mxhhpdiag"
  subnet_resource                         = local.internal_subnet
  dns_servers                             = local.internal_domain["dns_servers"]
  vm_starting_ip                          = 80
  vm_size                                 = "Standard_E32s_v3"
  data_disk = [
    { "name" = "db", "type" = "Premium_LRS", "size" = 2500, "lun" = 0, "caching" = "ReadOnly" },
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
  azure_devops_agent_tags                 = "DB, MsSql, Clinical, DR8"
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
      "logicalEnvironment" = "DR8"
      "backend"            = "true"
    },
  )
}

module "oracle8" {
  source = "../../../modules/terraform/oracle"

  resource_group_resource                 = azurerm_resource_group.env8
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-oraaz81"]
  availability_set_suffix                 = "-oraaz8-av"
  boot_diagnostics_storage_account_suffix = "oraaz8mxhhpdiag"
  subnet_resource                         = local.internal_subnet
  dns_servers                             = local.internal_domain["dns_servers"]
  vm_starting_ip                          = 100
  vm_size                                 = "Standard_E32s_v3"
  image_sku                               = "2012-R2-Datacenter"
  data_disk = [
    { "name" = "db", "type" = "Premium_LRS", "size" = 2000, "lun" = 0, "caching" = "ReadOnly" },
    { "name" = "backup", "type" = "Standard_LRS", "size" = 1000, "lun" = 1, "caching" = "None" },
  ]
  dsc_storage_container_resource          = local.dsc_storage_container
  dsc_extension_version                   = var.dsc_extension_version
  admin_username                          = var.local_admin_user
  admin_password                          = var.local_admin_pswd
  domain_name                             = local.internal_domain["name"]
  domain_join_account                     = data.terraform_remote_state.dr_shared.outputs.internal_domain_join_credential.username
  domain_join_password                    = data.terraform_remote_state.dr_shared.outputs.internal_domain_join_credential.password
  join_ou                                 = "OU=Oracle,OU=Azure DR,OU=Azure,${local.internal_domain_dn}"
  local_groups_members                    = { "Administrators" = formatlist("%s\\%s", local.internal_domain["netbiosname"], ["ORAADMIN"]) }
  batch_job_accounts                      = formatlist("%s\\%s", local.internal_domain["netbiosname"], [var.oracle_backup_account])
  firewall_ports                          = [1521]
  oracle_service_user                     = format("%s\\\\%s", local.internal_domain["netbiosname"], var.oracle_service_user)
  oracle_service_pswd                     = var.oracle_service_pswd
  oracle_sys_pswd                         = var.oracle_sys_pswd
  oracle_global_db_name                   = "caw4"
  oracle_install_files                    = var.oracle_install_files
  oracle_product_name                     = var.oracle_product_name
  oracle_product_version                  = var.oracle_product_version
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
  azure_devops_agent_tags                 = "DB, Oracle, DR8"
  azure_devops_pat_token                  = var.azure_devops_pat_token
  dependency_agent_extension_version      = var.dependency_agent_extension_version
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version

  tags = merge(
    local.tags,
    {
      "logicalEnvironment" = "DR8"
      "backend"            = "true"
    },
  )
}
