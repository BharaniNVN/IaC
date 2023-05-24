locals {
  quantity                       = coalesce(var.quantity, length(var.vmss_suffix))
  virtual_machine_scale_set_name = var.quantity == null ? formatlist("%s%s", var.resource_prefix, var.vmss_suffix) : [for i in range(1, var.quantity + 1) : format("%s%s%d", var.resource_prefix, concat(var.vmss_suffix, [""])[0], i)]
  boot_diag_default_suffix       = "mxhhpdiag"
  boot_diag_actual_suffix        = var.boot_diagnostics_storage_account_suffix != "" ? "" : local.boot_diag_default_suffix
  boot_diag_root_sanitized       = replace(coalesce(var.boot_diagnostics_storage_account_suffix, concat(var.vmss_suffix, [""])[0]), "/[-_]/", "")
  boot_diag_stor_acc_name        = lower(format("%s%s%s", var.resource_prefix, substr(local.boot_diag_root_sanitized, 0, min(length(local.boot_diag_root_sanitized), 24 - length(var.resource_prefix) - length(local.boot_diag_actual_suffix))), local.boot_diag_actual_suffix))
  boot_diag_stor_blob_ep         = try(azurerm_storage_account.boot_diagnostics[0].primary_blob_endpoint, var.boot_diagnostics_storage_blob_endpoint)
  loadbalancer_name              = format("%s%s%s", var.resource_prefix, concat(var.vmss_suffix, [""])[0], var.loadbalancer_suffix)
  lb_backend_address_pool_id     = var.enable_lb_backend_address_pool_association ? var.enable_internal_loadbalancer ? azurerm_lb_backend_address_pool.this[0].id : var.lb_backend_address_pool_id : null
  transform_lb_probes            = distinct([for i in var.lb_rules : format("%s_%d", keys(i["probe"])[0], values(i["probe"])[0]) if var.lb_sku == "Basic" && "Https" != keys(i["probe"])[0] || var.lb_sku == "Standard"])
  transform_lb_rules             = { for i in var.lb_rules : format("%s_%d", length(i["rule"]) == 0 ? keys(i["probe"])[0] : keys(i["rule"])[0], length(i["rule"]) == 0 ? values(i["probe"])[0] : values(i["rule"])[0]) => format("%s_%d", keys(i["probe"])[0], values(i["probe"])[0]) if var.lb_sku == "Basic" && "Https" != keys(i["probe"])[0] || var.lb_sku == "Standard" }
  lb_probes                      = false == var.enable_internal_loadbalancer ? {} : var.lb_enable_ha_ports && var.lb_sku == "Standard" && length(var.lb_rules) > 0 ? { tostring(local.transform_lb_probes[0]) = local.transform_lb_probes[0] } : { for p in local.transform_lb_probes : p => p }
  lb_rules                       = false == var.enable_internal_loadbalancer ? {} : var.lb_enable_ha_ports && var.lb_sku == "Standard" && length(var.lb_rules) > 0 ? { "all_0" = local.transform_lb_probes[0] } : local.transform_lb_rules
  marketplace_image              = var.plan_name != "" || var.plan_publisher != "" || var.plan_product != "" ? [""] : []
  resource_group_name            = var.resource_group_resource["name"]
  location                       = coalesce(var.location, var.resource_group_resource["location"])
  os_type                        = coalesce(var.os_type, length(regexall("\\w*[Ww]indows\\w*", var.image_offer)) > 0 ? "windows" : "linux")
}

resource "azurerm_marketplace_agreement" "this" {
  count = length(local.marketplace_image)

  publisher = var.plan_publisher
  offer     = var.plan_product
  plan      = var.plan_name
}

resource "azurerm_lb" "this" {
  count = var.enable_internal_loadbalancer ? 1 : 0

  name                = local.loadbalancer_name
  location            = local.location
  resource_group_name = local.resource_group_name
  sku                 = var.lb_sku

  frontend_ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = var.subnet_resource["id"]
    private_ip_address_allocation = var.lb_ip == null ? "Dynamic" : "Static"
    private_ip_address            = var.lb_ip == null ? null : cidrhost(var.subnet_resource["address_prefixes"][0], var.lb_ip)
  }

  tags = merge(
    var.tags,
    {
      "resource" = "load balancer"
    },
  )

  depends_on = [var.module_depends_on]
}

resource "azurerm_lb_backend_address_pool" "this" {
  count = var.enable_internal_loadbalancer ? 1 : 0

  name            = "BackendServerPool"
  loadbalancer_id = azurerm_lb.this[0].id
}

resource "azurerm_lb_probe" "this" {
  for_each = local.lb_probes

  name                = format("Probe_%s", each.value)
  loadbalancer_id     = azurerm_lb.this[0].id
  protocol            = split("_", each.value)[0]
  port                = split("_", each.value)[1]
  request_path        = contains(["https", "http"], split("_", each.value)[0]) ? "/" : null
  interval_in_seconds = 5
  number_of_probes    = 3
}

resource "azurerm_lb_rule" "this" {
  for_each = local.lb_rules

  name                           = format("Rule_%s", each.key)
  loadbalancer_id                = azurerm_lb.this[0].id
  frontend_ip_configuration_name = azurerm_lb.this[0].frontend_ip_configuration[0].name
  protocol                       = split("_", each.key)[0]
  frontend_port                  = split("_", each.key)[1]
  backend_port                   = split("_", each.key)[1]
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.this[0].id]
  probe_id                       = azurerm_lb_probe.this[each.value].id
  idle_timeout_in_minutes        = 5
  load_distribution              = var.lb_load_distribution
}

resource "azurerm_storage_account" "boot_diagnostics" {
  count = var.enable_boot_diagnostics_storage_account ? 1 : 0

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

resource "azurerm_windows_virtual_machine_scale_set" "this" {
  for_each = local.os_type == "windows" ? toset(local.virtual_machine_scale_set_name) : []

  name                        = each.key
  location                    = local.location
  resource_group_name         = local.resource_group_name
  sku                         = var.vmss_size
  instances                   = var.instances
  computer_name_prefix        = coalesce(var.computer_name_prefix, each.key)
  admin_username              = var.admin_username
  admin_password              = var.admin_password
  enable_automatic_updates    = var.enable_automatic_updates
  extensions_time_budget      = var.extensions_time_budget
  eviction_policy             = var.priority == "Spot" ? var.eviction_policy : null
  license_type                = var.license_type
  max_bid_price               = var.priority == "Spot" ? var.max_bid_price : null
  overprovision               = var.overprovision
  platform_fault_domain_count = var.platform_fault_domain_count
  priority                    = var.priority
  provision_vm_agent          = true
  scale_in_policy             = var.scale_in_policy
  single_placement_group      = var.single_placement_group
  timezone                    = var.timezone
  upgrade_mode                = var.upgrade_mode

  dynamic "automatic_os_upgrade_policy" {
    for_each = var.upgrade_mode == "Automatic" ? [""] : []

    content {
      disable_automatic_rollback  = var.disable_automatic_rollback
      enable_automatic_os_upgrade = var.enable_automatic_os_upgrade
    }
  }

  dynamic "boot_diagnostics" {
    for_each = local.boot_diag_stor_blob_ep != null ? [local.boot_diag_stor_blob_ep] : []

    content {
      storage_account_uri = boot_diagnostics.value
    }
  }

  dynamic "data_disk" {
    for_each = var.data_disk

    content {
      caching              = data_disk.value["caching"]
      storage_account_type = data_disk.value["type"]
      disk_size_gb         = data_disk.value["size"]
      lun                  = data_disk.value["lun"]
    }
  }

  dynamic "extension" {
    for_each = var.extension

    content {
      name                       = extension.value["name"]
      publisher                  = extension.value["publisher"]
      type                       = extension.value["type"]
      type_handler_version       = extension.value["type_handler_version"]
      auto_upgrade_minor_version = true
      protected_settings         = lookup(extension.value, "protected_settings", null)
      provision_after_extensions = lookup(extension.value, "provision_after_extensions", null)
      settings                   = lookup(extension.value, "settings", null)
    }
  }

  network_interface {
    name                          = format("%s%s", each.key, var.network_interface_suffix)
    dns_servers                   = var.dns_servers
    enable_accelerated_networking = var.enable_accelerated_networking
    enable_ip_forwarding          = var.enable_ip_forwarding
    primary                       = true

    ip_configuration {
      name                                   = "ipconfig"
      load_balancer_backend_address_pool_ids = compact([local.lb_backend_address_pool_id])
      primary                                = true
      subnet_id                              = var.subnet_resource["id"]
    }
  }

  os_disk {
    caching              = var.os_disk_caching
    storage_account_type = var.os_managed_disk_type
    disk_size_gb         = var.os_disk_size_gb

    dynamic "diff_disk_settings" {
      for_each = var.enable_ephemeral_os_disk ? [""] : []

      content {
        option = "Local"
      }
    }
  }

  dynamic "plan" {
    for_each = local.marketplace_image

    content {
      name      = var.plan_name
      publisher = var.plan_publisher
      product   = var.plan_product
    }
  }

  dynamic "rolling_upgrade_policy" {
    for_each = contains(["Automatic", "Rolling"], var.upgrade_mode) ? [""] : []

    content {
      max_batch_instance_percent              = var.max_batch_instance_percent
      max_unhealthy_instance_percent          = var.max_unhealthy_instance_percent
      max_unhealthy_upgraded_instance_percent = var.max_unhealthy_upgraded_instance_percent
      pause_time_between_batches              = var.pause_time_between_batches
    }
  }

  dynamic "secret" {
    for_each = var.keyvault_id != null ? [var.keyvault_id] : []

    content {
      key_vault_id = secret.value

      dynamic "certificate" {
        for_each = var.certificate_urls

        content {
          url   = certificate.value
          store = var.certificate_store_name
        }
      }
    }
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  dynamic "terminate_notification" {
    for_each = var.enable_terminate_notification ? [""] : []

    content {
      enabled = var.enable_terminate_notification
      timeout = var.terminate_notification_timeout
    }
  }

  tags = merge(
    var.tags,
    {
      "resource" = "virtual machine scale set"
    },
  )

  depends_on = [azurerm_marketplace_agreement.this]

  lifecycle {
    ignore_changes = [timezone]
  }
}

resource "azurerm_linux_virtual_machine_scale_set" "this" {
  for_each = local.os_type == "windows" ? [] : toset(local.virtual_machine_scale_set_name)

  name                            = each.key
  location                        = local.location
  resource_group_name             = local.resource_group_name
  sku                             = var.vmss_size
  instances                       = var.instances
  computer_name_prefix            = coalesce(var.computer_name_prefix, each.key)
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = var.admin_password == null
  extensions_time_budget          = var.extensions_time_budget
  eviction_policy                 = var.priority == "Spot" ? var.eviction_policy : null
  max_bid_price                   = var.priority == "Spot" ? var.max_bid_price : null
  overprovision                   = var.overprovision
  platform_fault_domain_count     = var.platform_fault_domain_count
  priority                        = var.priority
  provision_vm_agent              = true
  scale_in_policy                 = var.scale_in_policy
  single_placement_group          = var.single_placement_group
  upgrade_mode                    = var.upgrade_mode

  dynamic "admin_ssh_key" {
    for_each = var.admin_password != null ? [] : var.ssh_keys

    content {
      public_key = admin_ssh_key.value
      username   = var.admin_username
    }
  }

  dynamic "automatic_os_upgrade_policy" {
    for_each = var.upgrade_mode == "Automatic" ? [""] : []

    content {
      disable_automatic_rollback  = var.disable_automatic_rollback
      enable_automatic_os_upgrade = var.enable_automatic_os_upgrade
    }
  }

  dynamic "boot_diagnostics" {
    for_each = local.boot_diag_stor_blob_ep != null ? [local.boot_diag_stor_blob_ep] : []

    content {
      storage_account_uri = boot_diagnostics.value
    }
  }

  dynamic "data_disk" {
    for_each = var.data_disk

    content {
      caching              = data_disk.value["caching"]
      storage_account_type = data_disk.value["type"]
      disk_size_gb         = data_disk.value["size"]
      lun                  = data_disk.value["lun"]
    }
  }

  dynamic "extension" {
    for_each = var.extension

    content {
      name                       = extension.value["name"]
      publisher                  = extension.value["publisher"]
      type                       = extension.value["type"]
      type_handler_version       = extension.value["type_handler_version"]
      auto_upgrade_minor_version = true
      protected_settings         = lookup(extension.value, "protected_settings", null)
      provision_after_extensions = lookup(extension.value, "provision_after_extensions", null)
      settings                   = lookup(extension.value, "settings", null)
    }
  }

  network_interface {
    name                          = format("%s%s", each.key, var.network_interface_suffix)
    dns_servers                   = var.dns_servers
    enable_accelerated_networking = var.enable_accelerated_networking
    enable_ip_forwarding          = var.enable_ip_forwarding
    primary                       = true

    ip_configuration {
      name                                   = "ipconfig"
      load_balancer_backend_address_pool_ids = compact([local.lb_backend_address_pool_id])
      primary                                = true
      subnet_id                              = var.subnet_resource["id"]
    }
  }

  os_disk {
    caching              = var.os_disk_caching
    storage_account_type = var.os_managed_disk_type
    disk_size_gb         = var.os_disk_size_gb

    dynamic "diff_disk_settings" {
      for_each = var.enable_ephemeral_os_disk ? [""] : []

      content {
        option = "Local"
      }
    }
  }

  dynamic "plan" {
    for_each = local.marketplace_image

    content {
      name      = var.plan_name
      publisher = var.plan_publisher
      product   = var.plan_product
    }
  }

  dynamic "rolling_upgrade_policy" {
    for_each = contains(["Automatic", "Rolling"], var.upgrade_mode) ? [""] : []

    content {
      max_batch_instance_percent              = var.max_batch_instance_percent
      max_unhealthy_instance_percent          = var.max_unhealthy_instance_percent
      max_unhealthy_upgraded_instance_percent = var.max_unhealthy_upgraded_instance_percent
      pause_time_between_batches              = var.pause_time_between_batches
    }
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  dynamic "secret" {
    for_each = var.keyvault_id != null ? [var.keyvault_id] : []

    content {
      key_vault_id = secret.value

      dynamic "certificate" {
        for_each = var.certificate_urls

        content {
          url = certificate.value
        }
      }
    }
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  dynamic "terminate_notification" {
    for_each = var.enable_terminate_notification ? [""] : []

    content {
      enabled = var.enable_terminate_notification
      timeout = var.terminate_notification_timeout
    }
  }

  tags = merge(
    var.tags,
    {
      "resource" = "virtual machine scale set"
    },
  )

  depends_on = [azurerm_marketplace_agreement.this]
}
