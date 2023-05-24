locals {
  location                 = coalesce(var.location, var.resource_group_resource["location"])
  resource_group_name      = var.resource_group_resource["name"]
  availability_set_name    = format("%s%s", var.resource_prefix, coalesce(var.availability_set_suffix, format("%s-av", concat(var.virtual_machine_suffix, [""])[0])))
  boot_diag_default_suffix = "mxhhpdiag"
  boot_diag_root_sanitized = replace(coalesce(var.boot_diagnostics_storage_account_suffix, concat(var.virtual_machine_suffix, [""])[0]), "/[-_]/", "")
  boot_diag_actual_suffix  = var.boot_diagnostics_storage_account_suffix != "" ? "" : local.boot_diag_default_suffix
  boot_diag_stor_acc_name  = lower(format("%s%s%s", var.resource_prefix, substr(local.boot_diag_root_sanitized, 0, min(length(local.boot_diag_root_sanitized), 24 - length(var.resource_prefix) - length(local.boot_diag_actual_suffix))), local.boot_diag_actual_suffix))
  virtual_machine_name     = formatlist("%s%s", var.resource_prefix, var.virtual_machine_suffix)
  ip_address               = cidrhost((var.subnet_resource["address_prefixes"][0]), var.vm_starting_ip)
}

resource "azurerm_marketplace_agreement" "this" {
  publisher = var.plan_publisher
  offer     = var.plan_product
  plan      = var.plan_name
}

resource "azurerm_virtual_machine" "this" {
  name                  = format("%s%s", var.resource_prefix, concat(var.virtual_machine_suffix, [""])[0])
  location              = local.location
  resource_group_name   = local.resource_group_name
  network_interface_ids = [azurerm_network_interface.this.id]
  availability_set_id   = azurerm_availability_set.this.id
  vm_size               = var.vm_size

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  plan {
    name      = var.plan_name
    publisher = var.plan_publisher
    product   = var.plan_product
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.boot_diagnostics.primary_blob_endpoint
  }

  storage_os_disk {
    name              = format("%s%s", concat(local.virtual_machine_name, [""])[0], var.os_disk_suffix)
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = var.os_managed_disk_type
  }

  os_profile {
    computer_name  = concat(local.virtual_machine_name, [""])[0]
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = var.admin_password != null ? false : true
  }

  dynamic "os_profile_secrets" {
    for_each = var.keyvault_id != null ? [var.keyvault_id] : []

    content {
      source_vault_id = var.keyvault_id

      dynamic "vault_certificates" {
        for_each = var.certificate_urls

        content {
          certificate_url   = vault_certificates.value
          certificate_store = var.certificate_store_name
        }
      }
    }
  }

  dynamic "identity" {
    for_each = var.create_system_assigned_identity || length(var.user_assigned_identity_ids) > 0 ? [""] : []

    content {
      type         = var.create_system_assigned_identity && length(var.user_assigned_identity_ids) > 0 ? "SystemAssigned, UserAssigned" : var.create_system_assigned_identity ? "SystemAssigned" : "UserAssigned"
      identity_ids = length(var.user_assigned_identity_ids) > 0 ? var.user_assigned_identity_ids : null
    }
  }

  tags = merge(
    var.tags,
    {
      "resource" = "virtual machine"
    },
  )

  depends_on = [azurerm_marketplace_agreement.this]
}

resource "azurerm_network_interface" "this" {
  name                = format("%s%s%s", var.resource_prefix, concat(var.virtual_machine_suffix, [""])[0], var.network_interface_suffix)
  location            = local.location
  resource_group_name = local.resource_group_name
  dns_servers         = var.dns_servers

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = var.subnet_resource["id"]
    private_ip_address_allocation = var.vm_starting_ip == null ? "Dynamic" : "Static"
    private_ip_address            = var.vm_starting_ip == null ? null : local.ip_address
  }

  tags = merge(
    var.tags,
    {
      "resource" = "network interface"
    },
  )
}

resource "azurerm_availability_set" "this" {
  name                = local.availability_set_name
  location            = local.location
  resource_group_name = local.resource_group_name
  managed             = true

  tags = merge(
    var.tags,
    {
      "resource" = "availability set"
    },
  )
}

resource "azurerm_storage_account" "boot_diagnostics" {
  name                            = local.boot_diag_stor_acc_name
  resource_group_name             = local.resource_group_name
  location                        = local.location
  account_kind                    = "Storage"
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
  enable_https_traffic_only       = true
  min_tls_version                 = "TLS1_2"

  tags = merge(
    var.tags,
    {
      "resource" = "storage account"
    },
  )
}

resource "azurerm_virtual_machine_extension" "log_analytics_agent" {
  name                 = "Azure_Log_Analytics_Agent"
  virtual_machine_id   = azurerm_virtual_machine.this.id
  publisher            = "Microsoft.EnterpriseCloud.Monitoring"
  type                 = "OmsAgentForLinux"
  type_handler_version = var.log_analytics_extension_version["linux"]

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
}

resource "azurerm_firewall_network_rule_collection" "this" {
  count = var.azure_firewall_resource == null ? 0 : 1

  name                = "alienvault-outbound-custom-ports-collection"
  azure_firewall_name = var.azure_firewall_resource["name"]
  resource_group_name = var.azure_firewall_resource["resource_group_name"]
  priority            = var.azure_firewall_network_rule_collection_priority
  action              = "Allow"

  dynamic "rule" {
    for_each = var.alienvault_outbount_ports
    iterator = self

    content {
      name = "alienvault-connectivity-${self.key}"

      source_addresses = [azurerm_network_interface.this.private_ip_address]

      destination_ports = self.value

      destination_addresses = [
        "*",
      ]

      protocols = [
        self.key,
      ]
    }
  }
}
