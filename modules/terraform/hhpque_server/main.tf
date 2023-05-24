locals {
  location                 = coalesce(var.location, var.resource_group_resource["location"])
  ostype                   = module.virtual_machine.ostype
  resource_group_name      = var.resource_group_resource["name"]
  virtual_machine          = module.virtual_machine.id
  firewall_ports           = var.enable_internal_loadbalancer && length(var.firewall_ports) == 0 ? distinct(flatten([for i in var.lb_rules : concat(values(i["probe"]), length(i["rule"]) == 0 ? [] : values(i["rule"]))])) : var.firewall_ports
  dsc_zip_file_search_path = coalesce(var.dsc_zip_file_search_path, "${path.module}/configuration")
  dsc_zip_files            = fileset(local.dsc_zip_file_search_path, format("%s_*.zip", var.dsc_script_file_name))
  dsc_zip_file_name        = length(tolist(local.dsc_zip_files)) == 1 ? tolist(local.dsc_zip_files)[0] : format("%s.zip", var.dsc_script_file_name)
  dsc_zip_file_path        = format("%s/%s", local.dsc_zip_file_search_path, local.dsc_zip_file_name)
  dsc_script_file_name     = format("%s.ps1", var.dsc_script_file_name)
  dsc_function             = coalesce(var.dsc_configuration_name, var.dsc_script_file_name)
}

module "virtual_machine" {
  source = "../virtual_machine"

  quantity                                   = var.quantity
  resource_group_resource                    = var.resource_group_resource
  location                                   = local.location
  resource_prefix                            = var.resource_prefix
  availability_set_suffix                    = var.availability_set_suffix
  loadbalancer_suffix                        = var.loadbalancer_suffix
  enable_internal_loadbalancer               = var.enable_internal_loadbalancer
  lb_sku                                     = var.lb_sku
  lb_ip                                      = var.lb_ip
  lb_enable_ha_ports                         = var.lb_enable_ha_ports
  lb_rules                                   = var.lb_rules
  lb_load_distribution                       = var.lb_load_distribution
  enable_lb_backend_address_pool_association = var.enable_internal_loadbalancer
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
  admin_username                             = var.admin_username
  admin_password                             = var.admin_password
  patch_mode                                 = var.patch_mode
  timezone                                   = var.timezone
  create_system_assigned_identity            = var.create_system_assigned_identity
  tags                                       = var.tags
  user_assigned_identity_ids                 = var.user_assigned_identity_ids
  module_depends_on                          = var.module_depends_on
}

resource "azurerm_virtual_machine_extension" "script" {
  for_each = var.custom_script_extension_version == null || length(regexall("2012", var.image_sku)) == 0 ? [] : toset(module.virtual_machine.name)

  name                 = "WMF51_Install_Custom_Script"
  virtual_machine_id   = local.virtual_machine[each.value]
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = var.custom_script_extension_version

  protected_settings = <<PROTECTEDSETTINGS
    {
      "commandToExecute": "powershell -command \"& {Import-Module BitsTransfer; Start-BitsTransfer -Source http://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win8.1AndW2K12R2-KB3191564-x64.msu -Destination \\\"$env:systemroot\\Temp\\Win8.1AndW2K12R2-KB3191564-x64.msu\\\" -ErrorAction Stop; Start-Process -FilePath \\\"$env:systemroot\\System32\\wusa.exe\\\" -ArgumentList (\\\"$env:systemroot\\Temp\\Win8.1AndW2K12R2-KB3191564-x64.msu\\\", '/quiet', \\\"/log:$env:systemroot\\Temp\\wusa_Win8.1AndW2K12R2-KB3191564-x64.msu.log\\\") -Wait; exit $LASTEXITCODE}\""
    }
  PROTECTEDSETTINGS

  tags = merge(
    var.tags,
    {
      "resource" = "virtual machine extension"
    },
  )

  provisioner "local-exec" {
    command     = "$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop; Start-Sleep -Seconds 300"
    interpreter = ["pwsh", "-command"]

    when = create
  }

  timeouts {
    create = "15m"
  }
}

data "external" "failed_extension" {
  for_each = toset(module.virtual_machine.name)

  program = ["pwsh", "-command", "& {$vars=ConvertFrom-Json $([Console]::In.ReadLine()); $id = az vm extension list --resource-group $vars.rg --vm-name $vars.vm --query \"[?provisioningState=='Failed' && virtualMachineExtensionType=='DSC'].id\" -o tsv 2>&1; if ($LASTEXITCODE) {throw $id} elseif ($error.Count) { exit 1 } else {if ($id) {az vm extension delete --ids $id}; return '{}'} }"]

  query = {
    "rg" = local.resource_group_name
    "vm" = each.value
  }

  depends_on = [
    module.virtual_machine,
    azurerm_virtual_machine_extension.script
  ]
}

module "prepare_configuration" {
  source = "../prepare_configuration"

  vm_name                    = module.virtual_machine.name
  file_path                  = local.dsc_zip_file_path
  storage_container_resource = var.dsc_storage_container_resource
  module_depends_on          = data.external.failed_extension
}

resource "azurerm_virtual_machine_extension" "dsc" {
  for_each = var.dsc_extension_version == null ? [] : toset(module.virtual_machine.name)

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
        "JoinOU": "${var.join_ou}",
        "LocalGroupsMembers": ${jsonencode(var.local_groups_members)},
        "FoldersPermissions": ${jsonencode(var.folders_permissions)},
        "FirewallPorts": ${jsonencode(local.firewall_ports)},
        "FirstServer": "${module.virtual_machine.first}",
        "StorageShareFQDN": "${var.storage_share}",
        "DNSRecords": ${jsonencode(var.dns_records)},
        "SQLAliases": ${jsonencode(var.sql_aliases)},
        "HostsEntries": ${jsonencode(var.hosts_entries)},
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
        "Credential": {
          "UserName": "${var.domain_join_account}",
          "Password": "${var.domain_join_password}"
        },
        "ServiceRunAsAccountCredential": {
          "UserName": "${var.service_account_username}",
          "Password": "${var.service_account_password}"
        },
        "StorageShareAccessCredential": {
          "UserName": "${var.storage_share_access_username}",
          "Password": "${var.storage_share_access_password}"
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

  lifecycle {
    ignore_changes = [protected_settings]
  }

  timeouts {
    create = "60m"
  }
}

resource "azurerm_virtual_machine_extension" "log_analytics_agent" {
  for_each = var.log_analytics_workspace_resource == null ? [] : toset(module.virtual_machine.name)

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

  depends_on = [azurerm_virtual_machine_extension.script]

  timeouts {
    create = "60m"
  }
}

resource "azurerm_virtual_machine_extension" "pipelines_agent" {
  for_each = var.azure_devops_extension_version == null ? [] : toset(module.virtual_machine.name)

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

  depends_on = [azurerm_virtual_machine_extension.script]

  timeouts {
    create = "60m"
  }
}

resource "azurerm_virtual_machine_extension" "dependency_agent" {
  for_each = var.dependency_agent_extension_version == null ? [] : toset(module.virtual_machine.name)

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
  for_each = var.microsoft_antimalware_extension_version == null ? [] : toset(module.virtual_machine.name)

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

  depends_on = [azurerm_virtual_machine_extension.script]

  timeouts {
    create = "60m"
  }
}
