resource "azurerm_resource_group" "shared_dmz" {
  name     = "${local.deprecated_prefix}-shared-dmz-rg"
  location = var.location

  tags = merge(
    local.tags,
    {
      "logicalEnvironment" = "shared"
      "resource"           = "resource group"
    },
  )
}

module "dmz_domain_controller" {
  source = "../../../modules/terraform/active_directory"

  quantity                       = 1
  resource_group_resource        = azurerm_resource_group.shared_dmz
  resource_prefix                = local.deprecated_prefix
  virtual_machine_suffix         = ["-dmzdc"]
  subnet_resource                = azurerm_subnet.dmz_subnet
  dns_servers                    = ["192.168.20.10"]
  vm_starting_number             = 6
  vm_starting_ip                 = 5
  vm_size                        = "Standard_A2_v2"
  data_disk                      = [{ "name" = "", "type" = "Standard_LRS", "size" = 5, "lun" = 0, "caching" = "None" }]
  dsc_storage_container_resource = local.dsc_storage_container
  dsc_extension_version          = var.dsc_extension_version
  admin_username                 = var.local_admin_user
  admin_password                 = var.local_admin_pswd
  domain_name                    = var.dmz_domain
  domain_admin                   = var.cawdmz_admin_user
  domain_password                = var.cawdmz_admin_pswd
  ad_site                        = "AzurePROD"
  dns_forwarders                 = ["168.63.129.16"]
  forward_dns_zone_names = [
    "privatelink.blob.core.windows.net",
    "privatelink.file.core.windows.net",
    "privatelink.redis.cache.windows.net",
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
}

module "wsus" {
  source = "../../../modules/terraform/update_server"

  resource_group_resource                 = azurerm_resource_group.shared_dmz
  resource_prefix                         = local.deprecated_prefix
  virtual_machine_suffix                  = ["-wsus"]
  subnet_resource                         = azurerm_subnet.dmz_subnet
  dns_servers                             = module.dmz_domain_controller.dns_servers
  vm_starting_ip                          = 10
  vm_size                                 = "Standard_D2s_v3"
  data_disk                               = [{ "name" = "", "type" = "Standard_LRS", "size" = 512, "lun" = 0, "caching" = "None" }]
  dsc_storage_container_resource          = local.dsc_storage_container
  dsc_extension_version                   = var.dsc_extension_version
  admin_username                          = var.local_admin_user
  admin_password                          = var.local_admin_pswd
  domain_name                             = var.dmz_domain
  domain_join_account                     = var.cawdmz_join_user
  domain_join_password                    = var.cawdmz_join_pswd
  join_ou                                 = "OU=General,OU=Azure Prod,OU=Azure,${local.dmz_domain_dn}"
  upstream_server_name                    = "ops.${var.dmz_domain}"
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
    },
  )
}

module "sftp" {
  source = "../../../modules/terraform/sftp_server"

  resource_group_resource                 = azurerm_resource_group.shared_dmz
  resource_prefix                         = local.deprecated_prefix
  virtual_machine_suffix                  = ["-sftp"]
  subnet_resource                         = azurerm_subnet.dmz_subnet
  dns_servers                             = module.dmz_domain_controller.dns_servers
  vm_starting_ip                          = 101
  vm_size                                 = "Standard_F4s_v2"
  data_disk                               = [{ "name" = "", "type" = "Standard_LRS", "size" = 250, "lun" = 0, "caching" = "None" }]
  enable_internal_loadbalancer            = true
  lb_ip                                   = 100
  lb_rules                                = [{ "probe" = { "Tcp" = 22 }, "rule" = {} }]
  lb_load_distribution                    = "SourceIP"
  dsc_storage_container_resource          = local.dsc_storage_container
  dsc_extension_version                   = var.dsc_extension_version
  admin_username                          = var.local_admin_user
  admin_password                          = var.local_admin_pswd
  domain_name                             = var.dmz_domain
  domain_join_account                     = var.cawdmz_join_user
  domain_join_password                    = var.cawdmz_join_pswd
  join_ou                                 = "OU=General,OU=Azure Prod,OU=Azure,${local.dmz_domain_dn}"
  sql_admin_accounts                      = ["CAWPROD\\SQLADMIN"]
  sql_sa_password                         = var.sql_sa_pswd
  sql_port                                = 1593
  sftp_admin_account                      = var.sftp_admin_user
  sftp_admin_password                     = var.sftp_admin_pswd
  nxlog_conf                              = var.nxlog_conf
  nxlog_pem                               = var.nxlog_pem
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.this
  dependency_agent_extension_version      = var.dependency_agent_extension_version
  azure_firewall_resource                 = data.terraform_remote_state.shared.outputs.fw
  azure_firewall_public_ip_address        = [data.terraform_remote_state.shared.outputs.azure_firewall_public_ip_resource_prod_1.ip_address]
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version

  tags = merge(
    local.tags,
    {
      "application"        = "sftp"
      "logicalEnvironment" = "shared"
      "doNotShutdown"      = "true"
    },
  )
}

module "alienvault" {
  source = "../../../modules/terraform/alienvault_server/"

  resource_group_resource                         = azurerm_resource_group.shared_dmz
  resource_prefix                                 = local.deprecated_prefix
  virtual_machine_suffix                          = ["-alienvault"]
  subnet_resource                                 = azurerm_subnet.dmz_subnet
  dns_servers                                     = module.dmz_domain_controller.dns_servers
  vm_starting_ip                                  = 4
  vm_size                                         = "Standard_D2s_v3"
  admin_username                                  = var.alienvault_admin_user
  admin_password                                  = var.alienvault_admin_pswd
  log_analytics_workspace_resource                = azurerm_log_analytics_workspace.this
  azure_firewall_network_rule_collection_priority = 1010
  azure_firewall_resource                         = data.terraform_remote_state.shared.outputs.fw

  tags = merge(
    local.tags,
    {
      "application"        = "alienvault"
      "logicalEnvironment" = "shared"
    },
  )
}
module "sql_cc" {
  source = "../../../modules/terraform/sql_server"

  resource_group_resource                 = azurerm_resource_group.shared_dmz
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-ccaz01"]
  availability_set_suffix                 = "-ccaz-av"
  boot_diagnostics_storage_account_suffix = "ccazmxhhpdiag"
  subnet_resource                         = azurerm_subnet.dmz_subnet
  dns_servers                             = module.dmz_domain_controller.dns_servers
  vm_starting_ip                          = 17
  vm_size                                 = "Standard_F8s_v2"
  data_disk = [
    { "name" = "db", "type" = "StandardSSD_LRS", "size" = 100, "lun" = 0, "caching" = "ReadOnly" },
    { "name" = "logs", "type" = "StandardSSD_LRS", "size" = 10, "lun" = 1, "caching" = "None" },
  ]
  dsc_storage_container_resource          = local.dsc_storage_container
  dsc_extension_version                   = var.dsc_extension_version
  admin_username                          = var.local_admin_user
  admin_password                          = var.local_admin_pswd
  domain_name                             = var.dmz_domain
  domain_join_account                     = var.cawdmz_join_user
  domain_join_password                    = var.cawdmz_join_pswd
  join_ou                                 = "OU=General,OU=Azure Prod,OU=Azure,${local.dmz_domain_dn}"
  sql_admin_accounts                      = ["CAWPROD\\SQLADMIN"]
  sql_iso_path                            = var.sql_iso_path
  ssms_install_path                       = var.ssms_install_path
  sql_port                                = 1593
  nxlog_conf                              = var.nxlog_conf
  nxlog_pem                               = var.nxlog_pem
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.this
  dependency_agent_extension_version      = var.dependency_agent_extension_version
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version

  tags = merge(
    local.tags,
    {
      "doNotShutdown"      = "true"
      "backend"            = "true"
      "logicalEnvironment" = "shared"
    },
  )
}

module "sql_cc02" {
  source = "../../../modules/terraform/sql_server"

  resource_group_resource                 = azurerm_resource_group.shared_dmz
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-ccaz02"]
  availability_set_suffix                 = "-ccaz02-av"
  boot_diagnostics_storage_account_suffix = "ccaz02mxhhpdiag"
  subnet_resource                         = azurerm_subnet.dmz_subnet
  dns_servers                             = module.dmz_domain_controller.dns_servers
  vm_starting_ip                          = 18
  vm_size                                 = "Standard_F8s_v2"
  dsc_storage_container_resource          = local.dsc_storage_container
  dsc_extension_version                   = var.dsc_extension_version
  admin_username                          = var.local_admin_user
  admin_password                          = var.local_admin_pswd
  domain_name                             = var.dmz_domain
  domain_join_account                     = var.cawdmz_join_user
  domain_join_password                    = var.cawdmz_join_pswd
  join_ou                                 = "OU=General,OU=Azure Prod,OU=Azure,${local.dmz_domain_dn}"
  sql_admin_accounts                      = ["CAWPROD\\SQLADMIN"]
  sql_iso_path                            = var.sql_iso_path
  ssms_install_path                       = var.ssms_install_path
  sql_port                                = 1593
  nxlog_conf                              = var.nxlog_conf
  nxlog_pem                               = var.nxlog_pem
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.this
  dependency_agent_extension_version      = var.dependency_agent_extension_version
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version

  tags = merge(
    local.tags,
    {
      "doNotShutdown"      = "true"
      "backend"            = "true"
      "logicalEnvironment" = "shared"
    },
  )
}