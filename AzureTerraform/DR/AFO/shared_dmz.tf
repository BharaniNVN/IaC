resource "azurerm_resource_group" "shared_dmz" {
  name     = "${local.prefix}-shared-dmz-rg"
  location = var.location

  tags = merge(
    local.tags,
    {
      "logicalEnvironment" = "shared"
      "resource"           = "resource group"
    },
  )
}

module "hhpque" {
  source = "../../../modules/terraform/hhpque_server"

  resource_group_resource                 = azurerm_resource_group.shared_dmz
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-queaz01", "-queaz02"]
  availability_set_suffix                 = "-queaz-av"
  boot_diagnostics_storage_account_suffix = "queazmxhhpdiag"
  subnet_resource                         = local.dmz_subnet
  dns_servers                             = local.dmz_domain["dns_servers"]
  vm_starting_ip                          = 90
  vm_size                                 = "Standard_F4s"
  dsc_storage_container_resource          = local.dsc_storage_container
  dsc_extension_version                   = var.dsc_extension_version
  admin_username                          = var.local_admin_user
  admin_password                          = var.local_admin_pswd
  domain_name                             = local.dmz_domain["name"]
  domain_join_account                     = data.terraform_remote_state.dr_shared.outputs.dmz_domain_join_credential.username
  domain_join_password                    = data.terraform_remote_state.dr_shared.outputs.dmz_domain_join_credential.password
  join_ou                                 = "OU=QUE,OU=Azure DR,OU=Azure,${local.dmz_domain_dn}"
  local_groups_members                    = { "IIS_IUSRS" = formatlist("%s\\%s", local.dmz_domain["netbiosname"], [var.que_service_account_username]) }
  firewall_ports                          = [8000]
  service_account_username                = format("%s\\\\%s", local.dmz_domain["netbiosname"], var.que_service_account_username)
  service_account_password                = var.que_service_account_password
  folders_permissions = {
    format("%s\\%s", local.dmz_domain["netbiosname"], var.que_service_account_username) = { "Read" = ["C:\\BT\\QUE"], "FullControl" = ["C:\\Logs", "C:\\Temp"] },
    "IIS_IUSRS"                                                                         = { "Read" = ["C:\\BT\\QUE", "C:\\BT\\CAW_API"], "FullControl" = ["C:\\Logs", "C:\\Temp"] },
  }
  storage_share                           = azurerm_storage_account.this.primary_file_host
  storage_share_access_username           = azurerm_storage_account.this.name
  storage_share_access_password           = azurerm_storage_account.this.primary_access_key
  hosts_entries                           = local.hosts_entries
  nxlog_conf                              = var.nxlog_conf
  nxlog_pem                               = var.nxlog_pem
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.this
  azure_devops_extension_version          = var.azure_devops_extension_version
  azure_devops_account                    = var.azure_devops_account
  azure_devops_project                    = var.azure_devops_project
  azure_devops_deployment_group           = "US-Azure-NorthCentral-US-DR"
  azure_devops_agent_tags                 = "QUE_WEB,QUE_SVC"
  azure_devops_pat_token                  = var.azure_devops_pat_token
  dependency_agent_extension_version      = var.dependency_agent_extension_version
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version
  microsoft_antimalware_exclusion_files   = ["C:\\\\BT\\\\QUE"]

  tags = merge(
    local.tags,
    {
      "logicalEnvironment" = "shared"
    },
  )

  module_depends_on = [module.blob, module.file, module.redis]
}

module "wf" {
  source = "../../../modules/terraform/hhpwf_server"

  resource_group_resource                 = azurerm_resource_group.shared_dmz
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-wfaz01", "-wfaz02"]
  availability_set_suffix                 = "-wfaz-av"
  boot_diagnostics_storage_account_suffix = "wfazmxhhpdiag"
  subnet_resource                         = local.dmz_subnet
  dns_servers                             = local.dmz_domain["dns_servers"]
  vm_starting_ip                          = var.wf_lb_ip + 1
  vm_size                                 = "Standard_D4s_v3"
  image_sku                               = "2012-R2-Datacenter"
  enable_internal_loadbalancer            = true
  lb_ip                                   = var.wf_lb_ip
  lb_rules = [
    { "probe" = { "Tcp" = 443 }, "rule" = {} },
    { "probe" = { "Tcp" = 7001 }, "rule" = {} },
    { "probe" = { "Tcp" = 7002 }, "rule" = {} },
    { "probe" = { "Tcp" = 8000 }, "rule" = {} },
    { "probe" = { "Tcp" = 8001 }, "rule" = {} },
  ]
  lb_load_distribution       = "SourceIP"
  user_assigned_identity_ids = [azurerm_user_assigned_identity.key_vault_certificates.id]
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
  join_ou                        = "OU=WF,OU=Azure DR,OU=Azure,${local.dmz_domain_dn}"
  local_groups_members           = { "IIS_IUSRS" = formatlist("%s\\%s", local.dmz_domain["netbiosname"], [var.app_pool_account]) }
  app_pool_account               = format("%s\\\\%s", local.dmz_domain["netbiosname"], var.app_pool_account)
  certificate_subjects           = ["brightree.net"]
  folders_permissions = {
    "IIS_IUSRS" = { "Read" = ["C:\\BT\\API", "C:\\BT\\WEB", "C:\\AMS\\AMSRoot\\DocTemplates", "C:\\Applications\\Documents"], "FullControl" = ["C:\\Logs", "C:\\Temp"] },
  }
  dns_records = [
    { "name" = azurerm_storage_account.this.name, "zone" = format("privatelink%s", trimprefix(azurerm_storage_account.this.primary_file_host, azurerm_storage_account.this.name)), "ip" = module.file.private_ip_address },
    { "name" = azurerm_storage_account.this.name, "zone" = format("privatelink%s", trimprefix(azurerm_storage_account.this.primary_blob_host, azurerm_storage_account.this.name)), "ip" = module.blob.private_ip_address },
  ]
  hosts_entries                           = [for e in local.hosts_entries : { "name" = e.name, "ip" = e.ip == cidrhost(local.dmz_subnet.address_prefixes[0], var.wf_lb_ip) ? "127.0.0.1" : e.ip }]
  nxlog_conf                              = var.nxlog_conf
  nxlog_pem                               = var.nxlog_pem
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.this
  azure_devops_extension_version          = var.azure_devops_extension_version
  azure_devops_account                    = var.azure_devops_account
  azure_devops_project                    = var.azure_devops_project
  azure_devops_deployment_group           = "US-Azure-NorthCentral-US-DR"
  azure_devops_agent_tags                 = "WF"
  azure_devops_pat_token                  = var.azure_devops_pat_token
  dependency_agent_extension_version      = var.dependency_agent_extension_version
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version

  tags = merge(
    local.tags,
    {
      "logicalEnvironment" = "shared"
    },
  )

  module_depends_on = [
    azurerm_key_vault_access_policy.key_vault_certificates,
    module.blob,
    module.file,
    module.redis,
  ]
}

module "sync" {
  source = "../../../modules/terraform/sync_server"

  resource_group_resource                 = azurerm_resource_group.shared_dmz
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-syncaz01", "-syncaz02", "-syncaz03", "-cawwaz01"]
  availability_set_suffix                 = "-syncaz-av"
  boot_diagnostics_storage_account_suffix = "syncazmxhhpdiag"
  subnet_resource                         = local.dmz_subnet
  dns_servers                             = local.dmz_domain["dns_servers"]
  vm_starting_ip                          = var.sync_vm_starting_ip
  vm_size                                 = "Standard_E4s_v3"
  user_assigned_identity_ids              = [azurerm_user_assigned_identity.key_vault_certificates.id]
  certificate_urls                        = [local.cert_careanyware]
  key_vault_extension_version             = var.key_vault_extension_version
  key_vault_msi_client_id                 = azurerm_user_assigned_identity.key_vault_certificates.client_id
  dsc_storage_container_resource          = local.dsc_storage_container
  dsc_extension_version                   = var.dsc_extension_version
  admin_username                          = var.local_admin_user
  admin_password                          = var.local_admin_pswd
  domain_name                             = local.dmz_domain["name"]
  domain_join_account                     = data.terraform_remote_state.dr_shared.outputs.dmz_domain_join_credential.username
  domain_join_password                    = data.terraform_remote_state.dr_shared.outputs.dmz_domain_join_credential.password
  join_ou                                 = "OU=SYNC,OU=Azure DR,OU=Azure,${local.dmz_domain_dn}"
  local_groups_members                    = { "IIS_IUSRS" = formatlist("%s\\%s", local.dmz_domain["netbiosname"], [var.sync_app_pool_account]) }
  firewall_ports                          = [80, 443]
  folders_permissions = {
    "IIS_IUSRS" = { "Read" = ["C:\\BT\\API", "C:\\BT\\WEB", "C:\\AMS\\AMSRoot\\DocTemplates", "C:\\Applications\\Documents"], "FullControl" = ["C:\\Logs", "C:\\Temp"] },
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
  azure_devops_agent_tags                 = "SYNC"
  azure_devops_pat_token                  = var.azure_devops_pat_token
  dependency_agent_extension_version      = var.dependency_agent_extension_version
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version

  tags = merge(
    local.tags,
    {
      "logicalEnvironment" = "shared"
    },
  )

  module_depends_on = [
    azurerm_key_vault_access_policy.key_vault_certificates,
    module.blob,
    module.file,
    module.redis,
  ]
}

module "login" {
  source = "../../../modules/terraform/web_server"

  resource_group_resource                 = azurerm_resource_group.shared_dmz
  resource_prefix                         = local.prefix
  virtual_machine_suffix                  = ["-lauaz01", "-lauaz02"]
  availability_set_suffix                 = "-lauaz-av"
  boot_diagnostics_storage_account_suffix = "lauazmxhhpdiag"
  subnet_resource                         = local.dmz_subnet
  dns_servers                             = local.dmz_domain["dns_servers"]
  vm_starting_ip                          = var.login_lb_ip + 1
  vm_size                                 = "Standard_D2s_v3"
  enable_internal_loadbalancer            = true
  lb_ip                                   = var.login_lb_ip
  lb_rules                                = [{ "probe" = { "Tcp" = 443 }, "rule" = {} }]
  lb_load_distribution                    = "SourceIP"
  user_assigned_identity_ids              = [azurerm_user_assigned_identity.key_vault_certificates.id]
  certificate_urls                        = [local.cert_careanyware]
  key_vault_extension_version             = var.key_vault_extension_version
  key_vault_msi_client_id                 = azurerm_user_assigned_identity.key_vault_certificates.client_id
  dsc_storage_container_resource          = local.dsc_storage_container
  dsc_extension_version                   = var.dsc_extension_version
  admin_username                          = var.local_admin_user
  admin_password                          = var.local_admin_pswd
  domain_name                             = local.dmz_domain["name"]
  domain_join_account                     = data.terraform_remote_state.dr_shared.outputs.dmz_domain_join_credential.username
  domain_join_password                    = data.terraform_remote_state.dr_shared.outputs.dmz_domain_join_credential.password
  join_ou                                 = "OU=WF,OU=Azure DR,OU=Azure,${local.dmz_domain_dn}"
  local_groups_members                    = { "IIS_IUSRS" = formatlist("%s\\%s", local.dmz_domain["netbiosname"], [var.app_pool_account]) }
  folders_permissions                     = { "IIS_IUSRS" = { "Read" = ["C:\\BT\\WEB"], "FullControl" = ["C:\\Logs", "C:\\Temp"] } }
  hosts_entries                           = [for e in local.hosts_entries : { "name" = e.name, "ip" = e.ip == cidrhost(local.dmz_subnet.address_prefixes[0], var.login_lb_ip) ? "127.0.0.1" : e.ip }]
  nxlog_conf                              = var.nxlog_conf
  nxlog_pem                               = var.nxlog_pem
  log_analytics_extension_version         = var.log_analytics_extension_version
  log_analytics_workspace_resource        = azurerm_log_analytics_workspace.this
  azure_devops_extension_version          = var.azure_devops_extension_version
  azure_devops_account                    = var.azure_devops_account
  azure_devops_project                    = var.azure_devops_project
  azure_devops_deployment_group           = "US-Azure-NorthCentral-US-DR"
  azure_devops_agent_tags                 = "LOGIN, AUTH, LAU"
  azure_devops_pat_token                  = var.azure_devops_pat_token
  dependency_agent_extension_version      = var.dependency_agent_extension_version
  microsoft_antimalware_extension_version = var.microsoft_antimalware_extension_version

  tags = merge(
    local.tags,
    {
      "logicalEnvironment" = "shared"
    },
  )

  module_depends_on = [
    azurerm_key_vault_access_policy.key_vault_certificates,
    module.blob,
    module.file,
    module.redis,
  ]
}
