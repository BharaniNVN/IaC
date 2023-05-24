locals {
  location                 = coalesce(var.location, var.resource_group_resource["location"])
  ostype                   = module.virtual_machine.ostype
  resource_group_name      = var.resource_group_resource["name"]
  virtual_machine          = module.virtual_machine.id
  dsc_zip_file_search_path = coalesce(var.dsc_zip_file_search_path, "${path.module}/configuration")
  dsc_zip_files            = fileset(local.dsc_zip_file_search_path, format("%s_*.zip", var.dsc_script_file_name))
  dsc_zip_file_name        = length(tolist(local.dsc_zip_files)) == 1 ? tolist(local.dsc_zip_files)[0] : format("%s.zip", var.dsc_script_file_name)
  dsc_zip_file_path        = format("%s/%s", local.dsc_zip_file_search_path, local.dsc_zip_file_name)
  dsc_script_file_name     = format("%s.ps1", var.dsc_script_file_name)
  dsc_function             = coalesce(var.dsc_configuration_name, var.dsc_script_file_name)
  firewall_translated_addr = var.azure_firewall_resource != null || length(var.azure_firewall_public_ip_address) > 0 ? var.enable_internal_loadbalancer ? { "lb" = module.virtual_machine.lb_ip_address } : module.virtual_machine.name_with_ip_address : {}
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
  keyvault_id                                = var.enable_key_vault_certificates_integration_using_extension ? null : var.keyvault_id
  certificate_store_name                     = var.enable_key_vault_certificates_integration_using_extension ? null : var.certificate_store_name
  certificate_urls                           = var.enable_key_vault_certificates_integration_using_extension ? null : var.certificate_urls
  admin_username                             = var.admin_username
  admin_password                             = var.admin_password
  patch_mode                                 = var.patch_mode
  timezone                                   = var.timezone
  create_system_assigned_identity            = var.create_system_assigned_identity
  tags                                       = var.tags
  user_assigned_identity_ids                 = var.user_assigned_identity_ids
  module_depends_on                          = var.module_depends_on
}

data "external" "failed_extension" {
  for_each = toset(module.virtual_machine.name)

  program = ["pwsh", "-command", "& {$vars=ConvertFrom-Json $([Console]::In.ReadLine()); $id = az vm extension list --resource-group $vars.rg --vm-name $vars.vm --query \"[?provisioningState=='Failed' && virtualMachineExtensionType=='DSC'].id\" -o tsv 2>&1; if ($LASTEXITCODE) {throw $id} elseif ($error.Count) { exit 1 } else {if ($id) {az vm extension delete --ids $id}; return '{}'} }"]

  query = {
    "rg" = local.resource_group_name
    "vm" = each.value
  }

  depends_on = [module.virtual_machine]
}

module "prepare_configuration" {
  source = "../prepare_configuration"

  vm_name                    = module.virtual_machine.name
  file_path                  = local.dsc_zip_file_path
  storage_container_resource = var.dsc_storage_container_resource
  module_depends_on          = data.external.failed_extension
}

resource "azurerm_virtual_machine_extension" "key_vault" {
  for_each = var.enable_key_vault_certificates_integration_using_extension && var.key_vault_extension_version != null && length(var.certificate_urls) > 0 ? toset(module.virtual_machine.name) : []

  name                       = "Key_Vault_Certificates"
  virtual_machine_id         = local.virtual_machine[each.value]
  publisher                  = "Microsoft.Azure.KeyVault"
  type                       = local.ostype == "windows" ? "KeyVaultForWindows" : "KeyVaultForLinux"
  type_handler_version       = var.key_vault_extension_version[local.ostype]
  auto_upgrade_minor_version = true

  settings = jsonencode(merge(
    {
      "secretsManagementSettings" = {
        "certificateStoreLocation" = var.key_vault_certificate_store_location
        "certificateStoreName"     = var.certificate_store_name
        "linkOnRenewal"            = local.ostype == "windows" ? var.key_vault_link_on_renewal : false
        "observedCertificates"     = distinct([for c in var.certificate_urls : join("/", chunklist(split("/", c), 5)[0])])
        "pollingIntervalInS"       = var.key_vault_polling_interval
        "requireInitialSync"       = true
      }
    },
    var.key_vault_msi_client_id == null ? {} : {
      "authenticationSettings" = merge(
        var.key_vault_msi_client_id == null ? {} : {
          "msiClientId" = var.key_vault_msi_client_id
        },
        {
          "msiEndpoint" = var.key_vault_msi_endpoint
        }
      )
    }
  ))

  tags = merge(
    var.tags,
    {
      "resource" = "virtual machine extension"
    },
  )

  timeouts {
    create = "15m"
  }
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
        "Folders": ${jsonencode(var.folders)},
        "SQLport": "${var.sql_port}",
        "SQLAdminAccounts": ${jsonencode(var.sql_admin_accounts)},
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
        "SqlSACredential": {
          "UserName": "PLACEHOLDER_DO_NOT_USE",
          "Password": "${var.sql_sa_password}"
        },
        "SFTPAdminCredential": {
          "UserName": "${var.sftp_admin_account}",
          "Password": "${var.sftp_admin_password}"
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

  depends_on = [azurerm_virtual_machine_extension.key_vault]

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

  timeouts {
    create = "60m"
  }
}

resource "azurerm_firewall_nat_rule_collection" "this" {
  count = signum(length(local.firewall_translated_addr))

  name                = format("%s%s", var.resource_prefix, concat(var.virtual_machine_suffix, [""])[0])
  azure_firewall_name = var.azure_firewall_resource["name"]
  resource_group_name = var.azure_firewall_resource["resource_group_name"]
  priority            = var.rule_collection_priority
  action              = "Dnat"

  dynamic "rule" {
    for_each = local.firewall_translated_addr
    iterator = self

    content {
      name                  = "ssh-${self.key}"
      destination_addresses = [var.azure_firewall_public_ip_address[index(keys(local.firewall_translated_addr), self.key)]]
      destination_ports     = ["22"]
      source_addresses      = ["*"]
      translated_address    = self.value
      translated_port       = "22"
      protocols = [
        "TCP",
      ]
    }
  }
}
