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

  quantity                                = 1
  resource_group_resource                 = azurerm_resource_group.shared_internal
  resource_prefix                         = local.deprecated_prefix
  virtual_machine_suffix                  = ["-proddc"]
  subnet_resource                         = azurerm_subnet.cawprod_subnet
  dns_servers                             = ["192.168.10.10"]
  vm_starting_number                      = 4
  vm_starting_ip                          = 5
  vm_size                                 = "Standard_A2_v2"
  data_disk                               = [{ "name" = "", "type" = "Standard_LRS", "size" = 5, "lun" = 0, "caching" = "None" }]
  dsc_storage_container_resource          = local.dsc_storage_container
  dsc_extension_version                   = var.dsc_extension_version
  admin_username                          = var.local_admin_user
  admin_password                          = var.local_admin_pswd
  domain_name                             = var.internal_domain
  domain_admin                            = var.cawprod_admin_user
  domain_password                         = var.cawprod_admin_pswd
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

  module_depends_on = [module.blob_8]
}
