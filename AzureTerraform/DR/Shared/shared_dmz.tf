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

  quantity                                = 1
  resource_group_resource                 = azurerm_resource_group.shared_dmz
  resource_prefix                         = local.deprecated_prefix
  virtual_machine_suffix                  = ["-dmzdc"]
  subnet_resource                         = azurerm_subnet.dmz_subnet
  dns_servers                             = ["192.168.20.10"]
  vm_starting_number                      = 4
  vm_starting_ip                          = 5
  vm_size                                 = "Standard_A2_v2"
  data_disk                               = [{ "name" = "", "type" = "Standard_LRS", "size" = 5, "lun" = 0, "caching" = "None" }]
  dsc_storage_container_resource          = local.dsc_storage_container
  dsc_extension_version                   = var.dsc_extension_version
  admin_username                          = var.local_admin_user
  admin_password                          = var.local_admin_pswd
  domain_name                             = var.dmz_domain
  domain_admin                            = var.cawdmz_admin_user
  domain_password                         = var.cawdmz_admin_pswd
  ad_site                                 = "AzureDR"
  dns_forwarders                          = ["168.63.129.16"]
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
  data_disk                               = [{ "name" = "", "type" = "Standard_LRS", "size" = 300, "lun" = 0, "caching" = "None" }]
  dsc_storage_container_resource          = local.dsc_storage_container
  dsc_extension_version                   = var.dsc_extension_version
  admin_username                          = var.local_admin_user
  admin_password                          = var.local_admin_pswd
  domain_name                             = var.dmz_domain
  domain_join_account                     = var.cawdmz_join_user
  domain_join_password                    = var.cawdmz_join_pswd
  join_ou                                 = "OU=General,OU=Azure DR,OU=Azure,${local.dmz_domain_dn}"
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
