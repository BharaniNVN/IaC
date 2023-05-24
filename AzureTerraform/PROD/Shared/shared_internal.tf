resource "azurerm_resource_group" "shared_internal" {
  name     = "${local.deprecated_prefix}-shared-internal-rg"
  location = var.location

  tags = merge(
    local.tags,
    {
      "logicalEnvironment" = "shared"
      "resource"           = "resource group"
    },
  )
}

module "internal_domain_controller" {
  source = "../../../modules/terraform/active_directory"

  quantity                       = 1
  resource_group_resource        = azurerm_resource_group.shared_internal
  resource_prefix                = local.deprecated_prefix
  virtual_machine_suffix         = ["-intdc"]
  subnet_resource                = azurerm_subnet.cawprod_subnet
  dns_servers                    = ["192.168.10.10"]
  vm_starting_number             = 6
  vm_starting_ip                 = 5
  vm_size                        = "Standard_A2_v2"
  data_disk                      = [{ "name" = "", "type" = "Standard_LRS", "size" = 5, "lun" = 0, "caching" = "None" }]
  dsc_storage_container_resource = local.dsc_storage_container
  dsc_extension_version          = var.dsc_extension_version
  admin_username                 = var.local_admin_user
  admin_password                 = var.local_admin_pswd
  domain_name                    = var.internal_domain
  domain_admin                   = var.cawprod_admin_user
  domain_password                = var.cawprod_admin_pswd
  ad_site                        = "AzurePROD"
  dns_forwarders                 = ["168.63.129.16"]
  forward_dns_zone_names = [
    "privatelink.blob.core.windows.net",
    "privatelink.file.core.windows.net",
  ]
  dns_records = [
    { "name" = azurerm_storage_account.ops.name, "zone" = format("privatelink%s", trimprefix(azurerm_storage_account.ops.primary_file_host, azurerm_storage_account.ops.name)), "ip" = module.file.private_ip_address },
  ]
  nxlog_conf                              = var.nxlog_conf
  nxlog_pem                               = var.nxlog_pem
  custom_script_extension_version         = var.custom_script_extension_version
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.this
  dependency_agent_extension_version      = var.dependency_agent_extension_version
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version

  tags = merge(
    local.tags,
    {
      "logicalEnvironment" = "shared"
      "doNotShutdown"      = "true"
    },
  )

  module_depends_on = [module.file]
}

module "sql" {
  source = "../../../modules/terraform/sql_server"

  resource_group_resource                 = azurerm_resource_group.shared_internal
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-cdwaz01"]
  availability_set_suffix                 = "-cdwaz-av"
  boot_diagnostics_storage_account_suffix = "cdwazmxhhpdiag"
  subnet_resource                         = azurerm_subnet.cawprod_subnet
  dns_servers                             = module.internal_domain_controller.dns_servers
  vm_starting_ip                          = 100
  vm_size                                 = "Standard_D8s_v3"
  data_disk = [
    { "name" = "db", "type" = "StandardSSD_LRS", "size" = 120, "lun" = 0, "caching" = "ReadOnly" },
    { "name" = "logs", "type" = "StandardSSD_LRS", "size" = 40, "lun" = 1, "caching" = "None" },
    { "name" = "temp", "type" = "StandardSSD_LRS", "size" = 60, "lun" = 2, "caching" = "ReadOnly" },
    { "name" = "backup", "type" = "Standard_LRS", "size" = 150, "lun" = 3, "caching" = "None" },
  ]
  dsc_storage_container_resource                 = local.dsc_storage_container
  dsc_extension_version                          = var.dsc_extension_version
  admin_username                                 = var.local_admin_user
  admin_password                                 = var.local_admin_pswd
  domain_name                                    = var.internal_domain
  domain_join_account                            = var.cawprod_join_user
  domain_join_password                           = var.cawprod_join_pswd
  join_ou                                        = "OU=MsSql,OU=Azure Prod,OU=Azure,${local.internal_domain_dn}"
  sql_sa_password                                = var.sql_sa_pswd
  sql_service_user                               = format("%s\\\\%s", local.internal_domain_netbios_name, var.sql_svc_user)
  sql_service_pass                               = var.sql_svc_pswd
  sql_agent_user                                 = format("%s\\\\%s", local.internal_domain_netbios_name, var.sql_agent_user)
  sql_agent_pass                                 = var.sql_agent_pswd
  sql_admin_accounts                             = ["SQLADMIN", format("%s\\CorpDataWhseAdmin", local.dmz_domain_netbios_name)]
  sql_iso_path                                   = var.sql_iso_path
  ssms_install_path                              = var.ssms_install_path
  sql_port                                       = 1593
  nxlog_conf                                     = var.nxlog_conf
  nxlog_pem                                      = var.nxlog_pem
  install_oracle_sql_developer                   = true
  install_oracle_client                          = true
  install_on_premises_data_gateway               = true
  on_premises_data_gateway_ad_application_id     = azuread_application.data_gateway.application_id
  on_premises_data_gateway_ad_application_secret = azuread_service_principal_password.data_gateway.value
  log_analytics_extension_version                = var.log_analytics_extension_version
  log_analytics_workspace_resource               = azurerm_log_analytics_workspace.this
  azure_devops_extension_version                 = var.azure_devops_extension_version
  azure_devops_account                           = var.azure_devops_account
  azure_devops_project                           = var.azure_devops_project
  azure_devops_deployment_group                  = "US-Azure-NorthCentral-Shared-Prod"
  azure_devops_agent_tags                        = "DB, MsSql"
  azure_devops_pat_token                         = var.azure_devops_pat_token
  dependency_agent_extension_version             = var.dependency_agent_extension_version
  microsoft_antimalware_extension_version        = var.microsoft_antimalware_extension_version

  tags = merge(
    local.tags,
    {
      "logicalEnvironment" = "shared"
      "doNotShutdown"      = "true"
      "backend"            = "true"
    },
  )

  module_depends_on = [module.file]
}

module "client_purge_sql" {
  source = "../../../modules/terraform/sql_server"

  resource_group_resource                 = azurerm_resource_group.shared_internal
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-puraz01"]
  availability_set_suffix                 = "-puraz-av"
  boot_diagnostics_storage_account_suffix = "purazmxhhpdiag"
  subnet_resource                         = azurerm_subnet.cawprod_subnet
  dns_servers                             = module.internal_domain_controller.dns_servers
  vm_starting_ip                          = 105
  vm_size                                 = "Standard_D4s_v3"
  data_disk = [
    { "name" = "db", "type" = "StandardSSD_LRS", "size" = 3000, "lun" = 0, "caching" = "ReadOnly" },
    { "name" = "logs", "type" = "StandardSSD_LRS", "size" = 500, "lun" = 1, "caching" = "None" },
    { "name" = "temp", "type" = "StandardSSD_LRS", "size" = 500, "lun" = 2, "caching" = "ReadOnly" },
    { "name" = "backup", "type" = "Standard_LRS", "size" = 2000, "lun" = 3, "caching" = "None" },
  ]
  dsc_storage_container_resource          = local.dsc_storage_container
  dsc_extension_version                   = var.dsc_extension_version
  admin_username                          = var.local_admin_user
  admin_password                          = var.local_admin_pswd
  domain_name                             = var.internal_domain
  domain_join_account                     = var.cawprod_join_user
  domain_join_password                    = var.cawprod_join_pswd
  local_groups_members                    = { "Administrators" = concat(formatlist("%s\\%s", local.internal_domain_netbios_name, ["SQLADMIN"]), formatlist("%s\\%s", local.dmz_domain_netbios_name, ["ClientPurgeVMAdmins"])) }
  join_ou                                 = "OU=MsSql,OU=Azure Prod,OU=Azure,${local.internal_domain_dn}"
  sql_sa_password                         = var.sql_sa_pswd
  smtp_user                               = module.sendgrid_apikey.sendgrid_api_key_username
  smtp_pswd                               = module.sendgrid_apikey.sendgrid_api_key_value
  smtp_server                             = data.azurerm_key_vault_secret.sendgrid_server_name.value
  from_address                            = "ClientPurgeVM@mxhhpprod.com"
  replyto_address                         = "ClientPurgeVM@mxhhpprod.com"
  smtp_port                               = "587"
  sql_service_user                        = format("%s\\\\%s", local.internal_domain_netbios_name, var.sql_svc_user)
  sql_service_pass                        = var.sql_svc_pswd
  sql_agent_user                          = format("%s\\\\%s", local.internal_domain_netbios_name, var.sql_agent_user)
  sql_agent_pass                          = var.sql_agent_pswd
  sql_admin_accounts                      = ["SQLADMIN", format("%s\\ClientPurgeVMAdmins", local.dmz_domain_netbios_name)]
  sql_iso_path                            = var.sql_iso_path
  ssms_install_path                       = var.ssms_install_path
  nxlog_conf                              = var.nxlog_conf
  nxlog_pem                               = var.nxlog_pem
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.this
  dependency_agent_extension_version      = var.dependency_agent_extension_version
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version

  tags = merge(
    local.tags,
    {
      "logicalEnvironment" = "shared"
      "doNotShutdown"      = "true"
      "backend"            = "true"
    },
  )

  module_depends_on = [module.file]
}

module "oraclereg" {
  source = "../../../modules/terraform/oracle"

  resource_group_resource                 = azurerm_resource_group.shared_internal
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-regorac01"]
  availability_set_suffix                 = "-regorac01"
  boot_diagnostics_storage_account_suffix = "regorac01mxhhpdiag"
  subnet_resource                         = azurerm_subnet.cawprod_subnet
  dns_servers                             = module.internal_domain_controller.dns_servers
  vm_starting_ip                          = 90
  vm_size                                 = "Standard_E32-16as_v4"
  image_sku                               = "2012-R2-Datacenter"
  data_disk = [
    { "name" = "db", "type" = "Premium_LRS", "size" = 4500, "lun" = 0, "caching" = "None" }
  ]
  dsc_storage_container_resource          = local.dsc_storage_container
  dsc_extension_version                   = var.dsc_extension_version
  admin_username                          = var.local_admin_user
  admin_password                          = var.local_admin_pswd
  domain_name                             = var.internal_domain
  domain_join_account                     = var.cawprod_join_user
  domain_join_password                    = var.cawprod_join_pswd
  join_ou                                 = "OU=Oracle,OU=Azure Prod,OU=Azure,${local.internal_domain_dn}"
  local_groups_members                    = { "Administrators" = concat(formatlist("%s\\%s", local.internal_domain_netbios_name, ["OraAdmin"])) }
  batch_job_accounts                      = formatlist("%s\\%s", local.internal_domain_netbios_name, [var.oracle_backup_account])
  firewall_ports                          = [1521]
  oracle_service_user                     = format("%s\\\\%s", local.internal_domain_netbios_name, var.oracle_service_user)
  oracle_service_pswd                     = var.oracle_service_pswd
  oracle_sys_pswd                         = var.oracle_sys_pswd
  oracle_global_db_name                   = "caw3"
  oracle_install_files                    = var.oracle_install_files
  oracle_product_name                     = var.oracle_product_name
  oracle_product_version                  = var.oracle_product_version
  deployment_agent_account                = format("%s\\\\%s", local.internal_domain_netbios_name, var.deployment_agent_user)
  deployment_agent_password               = var.deployment_agent_pswd
  nxlog_conf                              = var.nxlog_conf
  nxlog_pem                               = var.nxlog_pem
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.this
  azure_devops_extension_version          = var.azure_devops_extension_version
  azure_devops_account                    = var.azure_devops_account
  azure_devops_project                    = var.azure_devops_project
  azure_devops_deployment_group           = "US-Azure-NorthCentral-Shared-Prod"
  azure_devops_agent_tags                 = "DB, Oracle"
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
  module_depends_on = [module.file]
}
