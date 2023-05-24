locals {
  location                 = coalesce(var.location, var.resource_group_resource["location"])
  ostype                   = module.virtual_machine.ostype
  quantity                 = coalesce(var.quantity, length(var.virtual_machine_suffix))
  resource_group_name      = var.resource_group_resource["name"]
  virtual_machine          = merge(module.virtual_machine_primary.id, module.virtual_machine.id)
  virtual_machine_name     = compact(concat(module.virtual_machine_primary.name, module.virtual_machine.name))
  dsc_zip_file_search_path = coalesce(var.dsc_zip_file_search_path, "${path.module}/configuration")
  dsc_zip_files            = fileset(local.dsc_zip_file_search_path, format("%s_*.zip", var.dsc_script_file_name))
  dsc_zip_file_name        = length(tolist(local.dsc_zip_files)) == 1 ? tolist(local.dsc_zip_files)[0] : format("%s.zip", var.dsc_script_file_name)
  dsc_zip_file_path        = format("%s/%s", local.dsc_zip_file_search_path, local.dsc_zip_file_name)
  dsc_script_file_name     = format("%s.ps1", var.dsc_script_file_name)
  dsc_function             = coalesce(var.dsc_configuration_name, var.dsc_script_file_name)
}

module "virtual_machine_primary" {
  source = "../virtual_machine"

  quantity                                   = var.deploy_domain ? 1 : 0
  resource_group_resource                    = var.resource_group_resource
  location                                   = local.location
  resource_prefix                            = var.resource_prefix
  enable_availability_set                    = var.deploy_domain ? true : false
  availability_set_suffix                    = var.availability_set_suffix
  loadbalancer_suffix                        = var.loadbalancer_suffix
  enable_internal_loadbalancer               = var.deploy_domain ? var.enable_internal_loadbalancer : false
  lb_sku                                     = var.lb_sku
  lb_ip                                      = var.lb_ip
  lb_enable_ha_ports                         = var.lb_enable_ha_ports
  lb_rules                                   = var.lb_rules
  lb_load_distribution                       = var.lb_load_distribution
  enable_lb_backend_address_pool_association = var.deploy_domain ? var.enable_internal_loadbalancer : false
  enable_boot_diagnostics_storage_account    = var.deploy_domain ? true : false
  boot_diagnostics_storage_account_suffix    = var.boot_diagnostics_storage_account_suffix
  boot_diagnostics_storage_blob_endpoint     = var.boot_diagnostics_storage_blob_endpoint
  network_interface_suffix                   = var.network_interface_suffix
  subnet_resource                            = var.subnet_resource
  vm_starting_ip                             = var.vm_starting_ip
  dns_servers                                = var.dns_servers
  data_disk_suffix                           = var.data_disk_suffix
  data_disk                                  = var.data_disk
  virtual_machine_suffix                     = var.virtual_machine_suffix
  vm_starting_number                         = var.vm_starting_number
  vm_size                                    = var.vm_size
  image_sku                                  = var.image_sku
  image_version                              = var.image_version
  license_type                               = var.license_type
  os_disk_suffix                             = var.os_disk_suffix
  os_managed_disk_type                       = var.os_managed_disk_type
  admin_username                             = var.domain_admin
  admin_password                             = var.domain_password
  patch_mode                                 = var.patch_mode
  timezone                                   = var.timezone
  create_system_assigned_identity            = var.create_system_assigned_identity
  tags                                       = var.tags
  user_assigned_identity_ids                 = var.user_assigned_identity_ids
  module_depends_on                          = var.module_depends_on
}

module "virtual_machine" {
  source = "../virtual_machine"

  quantity                                   = var.deploy_domain ? var.quantity - 1 : var.quantity
  resource_group_resource                    = var.resource_group_resource
  location                                   = local.location
  resource_prefix                            = var.resource_prefix
  enable_availability_set                    = var.deploy_domain ? false : true
  availability_set_id                        = var.deploy_domain ? module.virtual_machine_primary.availability_set_id : null
  availability_set_suffix                    = var.availability_set_suffix
  loadbalancer_suffix                        = var.loadbalancer_suffix
  enable_internal_loadbalancer               = var.deploy_domain ? false : var.enable_internal_loadbalancer
  lb_sku                                     = var.lb_sku
  lb_ip                                      = var.lb_ip
  lb_enable_ha_ports                         = var.lb_enable_ha_ports
  lb_rules                                   = var.lb_rules
  lb_load_distribution                       = var.lb_load_distribution
  enable_lb_backend_address_pool_association = var.enable_internal_loadbalancer
  lb_backend_address_pool_id                 = var.deploy_domain ? var.enable_internal_loadbalancer ? module.virtual_machine_primary.lb_backend_address_pool_id : null : null
  enable_boot_diagnostics_storage_account    = var.deploy_domain ? false : true
  boot_diagnostics_storage_account_suffix    = var.boot_diagnostics_storage_account_suffix
  boot_diagnostics_storage_blob_endpoint     = var.deploy_domain ? module.virtual_machine_primary.boot_diagnostics_storage_blob_endpoint : null
  network_interface_suffix                   = var.network_interface_suffix
  subnet_resource                            = var.subnet_resource
  vm_starting_ip                             = var.deploy_domain ? var.vm_starting_ip + 1 : var.vm_starting_ip
  dns_servers                                = var.dns_servers
  data_disk_suffix                           = var.data_disk_suffix
  data_disk                                  = var.data_disk
  virtual_machine_suffix                     = var.virtual_machine_suffix
  vm_starting_number                         = var.deploy_domain ? var.vm_starting_number + 1 : var.vm_starting_number
  vm_size                                    = var.vm_size
  image_sku                                  = var.image_sku
  image_version                              = var.image_version
  license_type                               = var.license_type
  os_disk_suffix                             = var.os_disk_suffix
  os_managed_disk_type                       = var.os_managed_disk_type
  admin_username                             = var.admin_username
  admin_password                             = var.admin_password
  patch_mode                                 = var.patch_mode
  timezone                                   = var.timezone
  create_system_assigned_identity            = var.create_system_assigned_identity
  tags                                       = var.tags
  user_assigned_identity_ids                 = var.user_assigned_identity_ids
  module_depends_on                          = var.module_depends_on
}

data "external" "dsc_storage_account_ip_address" {
  count = var.deploy_domain ? 1 : 0

  program = ["pwsh", "-command", "& {$vars=ConvertFrom-Json $([Console]::In.ReadLine()); $result = @{}; $fqdn=\"$($vars.name).blob.core.windows.net\"; $result[\"ip\"]=[System.Net.Dns]::GetHostAddresses($fqdn).Where({$_.AddressFamily -eq 'InterNetwork'}).IPAddressToString; $result[\"fqdn\"]=$fqdn; return $result|ConvertTo-Json}"]

  query = {
    "name" = var.dsc_storage_container_resource["storage_account_name"]
  }
}

resource "azurerm_virtual_machine_extension" "script" {
  for_each = var.deploy_domain ? toset(local.virtual_machine_name) : []

  name                 = "Hosts_File_Custom_Script"
  virtual_machine_id   = local.virtual_machine[each.value]
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = var.custom_script_extension_version

  protected_settings = <<PROTECTEDSETTINGS
    {
      "commandToExecute": "powershell -command \"& {Add-Content -Path C:\\Windows\\System32\\drivers\\etc\\hosts -Value \"${lookup(data.external.dsc_storage_account_ip_address[0].result, "ip")}`t`t${lookup(data.external.dsc_storage_account_ip_address[0].result, "fqdn")}\" -Force}\""
    }
  PROTECTEDSETTINGS

  tags = merge(
    var.tags,
    {
      "resource" = "virtual machine extension"
    },
  )

  depends_on = [data.external.dsc_storage_account_ip_address]

  lifecycle {
    ignore_changes = [protected_settings]
  }
}

data "external" "failed_extension" {
  for_each = toset(local.virtual_machine_name)

  program = ["pwsh", "-command", "& {$vars=ConvertFrom-Json $([Console]::In.ReadLine()); $id = az vm extension list --resource-group $vars.rg --vm-name $vars.vm --query \"[?provisioningState=='Failed' && virtualMachineExtensionType=='DSC'].id\" -o tsv 2>&1; if ($LASTEXITCODE) {throw $id} elseif ($error.Count) { exit 1 } else {if ($id) {az vm extension delete --ids $id}; return '{}'} }"]

  query = {
    "rg" = local.resource_group_name
    "vm" = each.value
  }

  depends_on = [
    module.virtual_machine_primary,
    module.virtual_machine,
  ]
}

module "prepare_configuration" {
  source = "../prepare_configuration"

  vm_name                    = local.virtual_machine_name
  file_path                  = local.dsc_zip_file_path
  storage_container_resource = var.dsc_storage_container_resource
  module_depends_on          = data.external.failed_extension
}

resource "azurerm_virtual_machine_extension" "dsc" {
  for_each = var.dsc_extension_version == null ? [] : toset(local.virtual_machine_name)

  name                 = format("%s_%s", local.dsc_function, module.prepare_configuration.hashsum)
  virtual_machine_id   = local.virtual_machine[each.value]
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = var.dsc_extension_version

  settings = <<SETTINGS
    {
      "configuration": {
        "url": "${lookup(module.prepare_configuration.url, each.value)}",
        "script": "${local.dsc_script_file_name}",
        "function": "${local.dsc_function}"
      },
      "privacy": {
        "dataCollection": "Disable"
      },
      "configurationArguments": {
        "DomainName": "${var.domain_name}",
        "FirstDomainController": "${var.deploy_domain ? module.virtual_machine_primary.first : ""}",
        "ConfigurationDomainController": "${local.virtual_machine_name[0]}",
        "ADSite": "${var.ad_site}",
        "OUs": ${jsonencode(var.ad_ou)},
        "DNSForwarders": ${jsonencode(var.dns_forwarders)},
        "DNSRecords": ${jsonencode(var.dns_records)},
        "DNSServers": ${jsonencode(var.dns_servers)},
        "ForwardLookupZoneNames": ${jsonencode(var.forward_dns_zone_names)},
        "ReverseLookupZoneNames": ${jsonencode(var.reverse_dns_zone_names)},
        "TimeZone": "${var.timezone == null ? "" : var.timezone}",
        "NPMDPort": "${var.npmd_port}",
        "nxlog_conf": "${var.nxlog_conf}",
        "nxlog_pem": "${var.nxlog_pem}"
      }
    }
  SETTINGS

  protected_settings = <<PROTECTEDSETTINGS
    {
      "configurationUrlSasToken": "${module.prepare_configuration.sas_token}",
      "configurationArguments": {
        "DomainAdministratorCredential": {
          "UserName": "${var.domain_admin}",
          "Password": "${var.domain_password}"
        },
        "DomainJoinCredential": {
          "UserName": "${var.domain_join_account}",
          "Password": "${var.domain_join_password}"
        }
      }
    }
  PROTECTEDSETTINGS

  tags = merge(
    var.tags,
    {
      "resource" = "virtual machine extension"
    },
  )

  depends_on = [azurerm_virtual_machine_extension.script]

  lifecycle {
    ignore_changes = [protected_settings]
  }

  timeouts {
    create = "60m"
  }
}

resource "azurerm_virtual_machine_extension" "log_analytics_agent" {
  for_each = var.log_analytics_workspace_resource == null ? [] : toset(local.virtual_machine_name)

  name                 = "Azure_Log_Analytics_Agent"
  virtual_machine_id   = local.virtual_machine[each.value]
  publisher            = "Microsoft.EnterpriseCloud.Monitoring"
  type                 = local.ostype == "windows" ? "MicrosoftMonitoringAgent" : "OmsAgentForLinux"
  type_handler_version = var.log_analytics_extension_version[local.ostype]

  settings = <<SETTINGS
    {
      "workspaceId": "${var.log_analytics_workspace_resource["workspace_id"]}"
    }
  SETTINGS

  protected_settings = <<PROTECTEDSETTINGS
    {
      "workspaceKey": "${var.log_analytics_workspace_resource["primary_shared_key"]}"
    }
  PROTECTEDSETTINGS

  tags = merge(
    var.tags,
    {
      "resource" = "virtual machine extension"
    },
  )

  timeouts {
    create = "60m"
  }
}

resource "azurerm_virtual_machine_extension" "pipelines_agent" {
  for_each = var.azure_devops_extension_version == null ? [] : toset(local.virtual_machine_name)

  name                       = "Azure_Pipelines_Agent"
  virtual_machine_id         = local.virtual_machine[each.value]
  publisher                  = "Microsoft.VisualStudio.Services"
  type                       = "TeamServicesAgent"
  type_handler_version       = var.azure_devops_extension_version
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "VSTSAccountName": "${var.azure_devops_account}",
      "TeamProject": "${var.azure_devops_project}",
      "DeploymentGroup": "${var.azure_devops_deployment_group}",
      "AgentName": "${each.value}",
      "Tags": "${var.azure_devops_agent_tags}"
    }
  SETTINGS

  protected_settings = <<PROTECTEDSETTINGS
    {
      "PATToken": "${var.azure_devops_pat_token}"
    }
  PROTECTEDSETTINGS

  tags = merge(
    var.tags,
    {
      "resource" = "virtual machine extension"
    },
  )

  timeouts {
    create = "60m"
  }
}

resource "azurerm_virtual_machine_extension" "dependency_agent" {
  for_each = var.dependency_agent_extension_version == null ? [] : toset(local.virtual_machine_name)

  name                 = "Dependency_Agent"
  virtual_machine_id   = local.virtual_machine[each.value]
  publisher            = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                 = "DependencyAgentWindows"
  type_handler_version = var.dependency_agent_extension_version

  tags = merge(
    var.tags,
    {
      "resource" = "virtual machine extension"
    },
  )

  depends_on = [azurerm_virtual_machine_extension.log_analytics_agent]

  timeouts {
    create = "60m"
  }
}

resource "azurerm_virtual_machine_extension" "microsoft_antimalware" {
  for_each = var.microsoft_antimalware_extension_version == null ? [] : toset(local.virtual_machine_name)

  name                       = "Microsoft_Antimalware"
  virtual_machine_id         = local.virtual_machine[each.value]
  publisher                  = "Microsoft.Azure.Security"
  type                       = "IaaSAntimalware"
  type_handler_version       = var.microsoft_antimalware_extension_version
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "AntimalwareEnabled": true,
      "RealtimeProtectionEnabled": "true",
      "ScheduledScanSettings": {
        "isEnabled": "${var.microsoft_antimalware_enable_scheduled_scan}",
        "day": "${var.microsoft_antimalware_sheduled_scan_day}",
        "time": "${var.microsoft_antimalware_sheduled_scan_time}",
        "scanType": "${var.microsoft_antimalware_sheduled_scan_type}"
      },
      "Exclusions": {
        "Extensions": "${join(";", var.microsoft_antimalware_exclusion_extensions)}",
        "Paths": "${join(";", var.microsoft_antimalware_exclusion_files)}",
        "Processes": "${join(";", var.microsoft_antimalware_exclusion_processes)}"
      }
    }
  SETTINGS

  tags = merge(
    var.tags,
    {
      "resource" = "virtual machine extension"
    },
  )

  timeouts {
    create = "60m"
  }
}
