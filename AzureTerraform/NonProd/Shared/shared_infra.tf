resource "azurerm_resource_group" "shared_infra" {
  name     = "${local.prefix}-infra-rg"
  location = var.location

  tags = merge(
    local.tags,
    {
      "logicalEnvironment" = "shared"
      "resource"           = "resource group"
    },
  )
  lifecycle {
    prevent_destroy = true
  }
}

module "domain_controller" {
  source = "../../../modules/terraform/active_directory"

  resource_group_resource                 = azurerm_resource_group.shared_infra
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-dcaz01"]
  availability_set_suffix                 = "-dcaz-av"
  boot_diagnostics_storage_account_suffix = "dcazmxhhpdiag"
  subnet_resource                         = azurerm_subnet.shared
  dns_servers                             = ["10.105.128.165", "10.105.128.166"]
  vm_starting_ip                          = 5
  vm_size                                 = "Standard_D2s_v3"
  image_sku                               = "2019-Datacenter"
  data_disk                               = [{ "name" = "", "type" = "Standard_LRS", "size" = 5, "lun" = 0, "caching" = "None" }]
  dsc_storage_container_resource          = local.dsc_storage_container
  dsc_extension_version                   = var.dsc_extension_version
  admin_username                          = var.local_admin_user
  admin_password                          = var.local_admin_pswd
  domain_name                             = var.domain_name
  domain_admin                            = var.domain_admin_user
  domain_password                         = var.domain_admin_pswd
  domain_join_account                     = var.domain_join_user
  domain_join_password                    = var.domain_join_pswd
  ad_site                                 = "Azure"
  dns_forwarders                          = ["168.63.129.16"]
  forward_dns_zone_names = [
    data.azuread_domains.aad_domains.domains[0].domain_name,
    "privatelink.blob.core.windows.net",
    "privatelink.file.core.windows.net",
    "privatelink.redis.cache.windows.net",
  ]
  dns_records                             = local.dns_objects_ad
  custom_script_extension_version         = var.custom_script_extension_version
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.nonprod
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version
  nxlog_conf                              = var.nxlog_conf
  nxlog_pem                               = var.nxlog_pem

  tags = merge(
    local.tags,
    {
      "logicalEnvironment" = "shared"
      "doNotShutdown"      = "true"
    },
  )
}

module "domain_controller_2" {
  source = "../../../modules/terraform/active_directory"

  resource_group_resource                 = azurerm_resource_group.shared_infra
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-dcaz02"]
  availability_set_suffix                 = "-dcaz02-av"
  boot_diagnostics_storage_account_suffix = "dcaz2mxhhpdiag"
  subnet_resource                         = azurerm_subnet.shared
  dns_servers                             = ["10.105.128.166", "10.105.128.165"]
  vm_starting_ip                          = 6
  vm_size                                 = "Standard_D2s_v3"
  image_sku                               = "2019-Datacenter"
  data_disk                               = [{ "name" = "", "type" = "Standard_LRS", "size" = 5, "lun" = 0, "caching" = "None" }]
  dsc_storage_container_resource          = local.dsc_storage_container
  dsc_extension_version                   = var.dsc_extension_version
  admin_username                          = var.local_admin_user
  admin_password                          = var.local_admin_pswd
  domain_name                             = var.domain_name
  domain_admin                            = var.domain_admin_user
  domain_password                         = var.domain_admin_pswd
  domain_join_account                     = var.domain_join_user
  domain_join_password                    = var.domain_join_pswd
  ad_site                                 = "Azure"
  dns_forwarders                          = ["168.63.129.16"]
  forward_dns_zone_names = [
    data.azuread_domains.aad_domains.domains[0].domain_name,
    "privatelink.blob.core.windows.net",
    "privatelink.file.core.windows.net",
    "privatelink.redis.cache.windows.net",
  ]
  dns_records                             = local.dns_objects_ad
  custom_script_extension_version         = var.custom_script_extension_version
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.nonprod
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version
  nxlog_conf                              = var.nxlog_conf
  nxlog_pem                               = var.nxlog_pem

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

  resource_group_resource                 = azurerm_resource_group.shared_infra
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-wsusaz01"]
  availability_set_suffix                 = "-wsusaz-av"
  boot_diagnostics_storage_account_suffix = "wsusazmxhhpdiag"
  subnet_resource                         = azurerm_subnet.shared
  dns_servers                             = module.domain_controller.dns_servers
  vm_starting_ip                          = 10
  vm_size                                 = "Standard_D2s_v3"
  image_sku                               = "2019-Datacenter"
  data_disk                               = [{ "name" = "", "type" = "Standard_LRS", "size" = 300, "lun" = 0, "caching" = "None" }]
  dsc_storage_container_resource          = local.dsc_storage_container
  dsc_extension_version                   = var.dsc_extension_version
  admin_username                          = var.local_admin_user
  admin_password                          = var.local_admin_pswd
  domain_name                             = var.domain_name
  domain_join_account                     = var.domain_join_user
  domain_join_password                    = var.domain_join_pswd
  join_ou                                 = "OU=General,OU=Azure,OU=Servers,${local.domain_dn}"
  upstream_server_name                    = "CAWWSUS.${var.domain_name}"
  install_adconnect                       = true
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.nonprod
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version
  nxlog_conf                              = var.nxlog_conf
  nxlog_pem                               = var.nxlog_pem

  tags = merge(
    local.tags,
    {
      "logicalEnvironment" = "shared"
      "doNotShutdown"      = "true"
    },
  )
}

module "rdp_server" {
  source = "../../../modules/terraform/rdp_server"

  resource_group_resource                 = azurerm_resource_group.shared_infra
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-rdpaz01"]
  availability_set_suffix                 = "-rdpaz-av"
  boot_diagnostics_storage_account_suffix = "rdpazmxhhpdiag"
  subnet_resource                         = azurerm_subnet.shared
  dns_servers                             = module.domain_controller.dns_servers
  vm_starting_ip                          = 12
  vm_size                                 = "Standard_E4as_v4"
  data_disk                               = [{ "name" = "share", "type" = "Standard_LRS", "size" = 250, "lun" = 0, "caching" = "None" }]
  disk_size_gb                            = var.disk_size_gb
  dsc_storage_container_resource          = local.dsc_storage_container
  dsc_extension_version                   = var.dsc_extension_version
  admin_username                          = var.local_admin_user
  admin_password                          = var.local_admin_pswd
  domain_name                             = var.domain_name
  domain_join_account                     = var.domain_join_user
  domain_join_password                    = var.domain_join_pswd
  join_ou                                 = "OU=General,OU=Azure,OU=Servers,${local.domain_dn}"
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.nonprod
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version
  nxlog_conf                              = var.nxlog_conf
  nxlog_pem                               = var.nxlog_pem

  tags = merge(
    local.tags,
    {
      "application"        = "rdp server"
      "logicalEnvironment" = "shared"
    },
  )
}

module "sql" {
  source = "../../../modules/terraform/sql_server"

  resource_group_resource                 = azurerm_resource_group.shared_infra
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-cdwaz01"]
  availability_set_suffix                 = "-cdwaz-av"
  boot_diagnostics_storage_account_suffix = "cdwazmxhhpdiag"
  subnet_resource                         = azurerm_subnet.shared
  dns_servers                             = module.domain_controller.dns_servers
  vm_starting_ip                          = 16
  vm_size                                 = "Standard_D4s_v3"
  data_disk = [
    { "name" = "db", "type" = "StandardSSD_LRS", "size" = 70, "lun" = 0, "caching" = "ReadOnly" },
    { "name" = "logs", "type" = "StandardSSD_LRS", "size" = 40, "lun" = 1, "caching" = "None" },
    { "name" = "temp", "type" = "StandardSSD_LRS", "size" = 40, "lun" = 2, "caching" = "ReadOnly" },
    { "name" = "backup", "type" = "Standard_LRS", "size" = 150, "lun" = 3, "caching" = "None" },
  ]
  dsc_storage_container_resource                 = local.dsc_storage_container
  dsc_extension_version                          = var.dsc_extension_version
  admin_username                                 = var.local_admin_user
  admin_password                                 = var.local_admin_pswd
  domain_name                                    = var.domain_name
  domain_join_account                            = var.domain_join_user
  domain_join_password                           = var.domain_join_pswd
  join_ou                                        = "OU=MsSql,OU=Azure,OU=Servers,${local.domain_dn}"
  local_groups_members                           = { "Administrators" = formatlist("%s\\%s", local.domain_netbios_name, ["SqlAdmin", "CorpDataWhseAdmin"]) }
  sql_sa_password                                = var.sql_sa_pswd
  sql_service_user                               = format("%s\\\\%s", local.domain_netbios_name, var.sql_service_user)
  sql_service_pass                               = var.sql_service_pswd
  sql_agent_user                                 = format("%s\\\\%s", local.domain_netbios_name, var.sql_agent_user)
  sql_agent_pass                                 = var.sql_agent_pswd
  sql_admin_accounts                             = ["SqlAdmin", "CorpDataWhseAdmin"]
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
  log_analytics_workspace_resource               = azurerm_log_analytics_workspace.nonprod
  azure_devops_extension_version                 = var.azure_devops_extension_version
  azure_devops_account                           = var.azure_devops_account
  azure_devops_project                           = var.azure_devops_project
  azure_devops_deployment_group                  = "US-Azure-EastUs2-Shared-NonProd"
  azure_devops_agent_tags                        = "DB, MsSql"
  azure_devops_pat_token                         = var.azure_devops_pat_token
  dependency_agent_extension_version             = var.dependency_agent_extension_version
  microsoft_antimalware_extension_version        = var.microsoft_antimalware_extension_version

  tags = merge(
    local.tags,
    {
      "doNotShutdown"      = "true"
      "backend"            = "true"
      "logicalEnvironment" = "shared"
    },
  )
}

module "sql_cc" {
  source = "../../../modules/terraform/sql_server"

  resource_group_resource                 = azurerm_resource_group.shared_infra
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-ccaz01"]
  availability_set_suffix                 = "-ccaz-av"
  boot_diagnostics_storage_account_suffix = "ccazmxhhpdiag"
  subnet_resource                         = azurerm_subnet.shared
  dns_servers                             = module.domain_controller.dns_servers
  vm_starting_ip                          = 17
  vm_size                                 = "Standard_D4as_v4"
  data_disk = [
    { "name" = "db", "type" = "StandardSSD_LRS", "size" = 50, "lun" = 0, "caching" = "ReadOnly" },
    { "name" = "logs", "type" = "StandardSSD_LRS", "size" = 10, "lun" = 1, "caching" = "None" },
  ]
  dsc_storage_container_resource          = local.dsc_storage_container
  dsc_extension_version                   = var.dsc_extension_version
  admin_username                          = var.local_admin_user
  admin_password                          = var.local_admin_pswd
  domain_name                             = var.domain_name
  domain_join_account                     = var.domain_join_user
  domain_join_password                    = var.domain_join_pswd
  join_ou                                 = "OU=MsSql,OU=Azure,OU=Servers,${local.domain_dn}"
  local_groups_members                    = { "Administrators" = formatlist("%s\\%s", local.domain_netbios_name, ["SqlAdmin"]) }
  sql_sa_password                         = var.sql_sa_pswd
  sql_service_user                        = format("%s\\\\%s", local.domain_netbios_name, var.sql_service_user)
  sql_service_pass                        = var.sql_service_pswd
  sql_agent_user                          = format("%s\\\\%s", local.domain_netbios_name, var.sql_agent_user)
  sql_agent_pass                          = var.sql_agent_pswd
  sql_admin_accounts                      = ["SqlAdmin"]
  sql_iso_path                            = var.sql_iso_path
  ssms_install_path                       = var.ssms_install_path
  sql_port                                = 1593
  nxlog_conf                              = var.nxlog_conf
  nxlog_pem                               = var.nxlog_pem
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.nonprod
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

  resource_group_resource                 = azurerm_resource_group.shared_infra
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-ccaz02"]
  availability_set_suffix                 = "-ccaz02-av"
  boot_diagnostics_storage_account_suffix = "ccaz02mxhhpdiag"
  subnet_resource                         = azurerm_subnet.shared
  dns_servers                             = module.domain_controller.dns_servers
  vm_starting_ip                          = 18
  vm_size                                 = "Standard_D4as_v4"
  dsc_storage_container_resource          = local.dsc_storage_container
  dsc_extension_version                   = var.dsc_extension_version
  admin_username                          = var.local_admin_user
  admin_password                          = var.local_admin_pswd
  domain_name                             = var.domain_name
  domain_join_account                     = var.domain_join_user
  domain_join_password                    = var.domain_join_pswd
  join_ou                                 = "OU=MsSql,OU=Azure,OU=Servers,${local.domain_dn}"
  local_groups_members                    = { "Administrators" = formatlist("%s\\%s", local.domain_netbios_name, ["SqlAdmin"]) }
  sql_sa_password                         = var.sql_sa_pswd
  sql_service_user                        = format("%s\\\\%s", local.domain_netbios_name, var.sql_service_user)
  sql_service_pass                        = var.sql_service_pswd
  sql_agent_user                          = format("%s\\\\%s", local.domain_netbios_name, var.sql_agent_user)
  sql_agent_pass                          = var.sql_agent_pswd
  sql_admin_accounts                      = ["SqlAdmin"]
  sql_iso_path                            = var.sql_iso_path
  ssms_install_path                       = var.ssms_install_path
  sql_port                                = 1593
  nxlog_conf                              = var.nxlog_conf
  nxlog_pem                               = var.nxlog_pem
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.nonprod
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

module "alienvault" {
  source = "../../../modules/terraform/alienvault_server/"

  resource_group_resource                         = azurerm_resource_group.shared_infra
  resource_prefix                                 = local.prefix
  virtual_machine_suffix                          = ["-alienvault"]
  subnet_resource                                 = azurerm_subnet.shared
  dns_servers                                     = module.domain_controller.dns_servers
  vm_starting_ip                                  = 4
  vm_size                                         = "Standard_D2s_v3"
  admin_username                                  = var.alienvault_admin_user
  admin_password                                  = var.alienvault_admin_pswd
  log_analytics_workspace_resource                = azurerm_log_analytics_workspace.nonprod
  azure_firewall_network_rule_collection_priority = 1010
  azure_firewall_resource                         = azurerm_firewall.nonprod_fw

  tags = merge(
    local.tags,
    {
      "application"        = "alienvault"
      "logicalEnvironment" = "shared"
    },
  )
}