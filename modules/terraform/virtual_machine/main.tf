locals {
  quantity                   = coalesce(var.quantity, length(var.virtual_machine_suffix))
  virtual_machine_name       = var.quantity == null ? formatlist("%s%s", var.resource_prefix, var.virtual_machine_suffix) : [for i in range(var.vm_starting_number, var.quantity + var.vm_starting_number) : format("%s%s%d", var.resource_prefix, concat(var.virtual_machine_suffix, [""])[0], i)]
  availability_set_name      = format("%s%s", var.resource_prefix, coalesce(var.availability_set_suffix, format("%s-av", concat(var.virtual_machine_suffix, [""])[0])))
  availability_set_id        = try(azurerm_availability_set.this[0].id, var.availability_set_id)
  boot_diag_default_suffix   = "mxhhpdiag"
  boot_diag_actual_suffix    = var.boot_diagnostics_storage_account_suffix != "" ? "" : local.boot_diag_default_suffix
  boot_diag_root_sanitized   = replace(coalesce(var.boot_diagnostics_storage_account_suffix, concat(var.virtual_machine_suffix, [""])[0]), "/[-_]/", "")
  boot_diag_stor_acc_name    = lower(format("%s%s%s", var.resource_prefix, substr(local.boot_diag_root_sanitized, 0, min(length(local.boot_diag_root_sanitized), 24 - length(var.resource_prefix) - length(local.boot_diag_actual_suffix))), local.boot_diag_actual_suffix))
  boot_diag_stor_blob_ep     = try(azurerm_storage_account.boot_diagnostics[0].primary_blob_endpoint, var.boot_diagnostics_storage_blob_endpoint)
  data_disk                  = { for i in setproduct(local.virtual_machine_name, var.data_disk) : join("_", compact([i[0], i[1].name])) => i[1] }
  loadbalancer_name          = format("%s%s%s", var.resource_prefix, concat(var.virtual_machine_suffix, [""])[0], var.loadbalancer_suffix)
  lb_backend_address_pool_id = var.enable_lb_backend_address_pool_association ? var.enable_internal_loadbalancer ? azurerm_lb_backend_address_pool.this[0].id : var.lb_backend_address_pool_id : null
  transform_lb_probes        = distinct([for i in var.lb_rules : format("%s_%d", keys(i["probe"])[0], values(i["probe"])[0]) if var.lb_sku == "Basic" && "Https" != keys(i["probe"])[0] || var.lb_sku == "Standard"])
  transform_lb_rules         = { for i in var.lb_rules : format("%s_%d", length(i["rule"]) == 0 ? keys(i["probe"])[0] : keys(i["rule"])[0], length(i["rule"]) == 0 ? values(i["probe"])[0] : values(i["rule"])[0]) => format("%s_%d", keys(i["probe"])[0], values(i["probe"])[0]) if var.lb_sku == "Basic" && "Https" != keys(i["probe"])[0] || var.lb_sku == "Standard" }
  lb_probes                  = false == var.enable_internal_loadbalancer ? {} : var.lb_enable_ha_ports && var.lb_sku == "Standard" && length(var.lb_rules) > 0 ? { tostring(local.transform_lb_probes[0]) = local.transform_lb_probes[0] } : { for p in local.transform_lb_probes : p => p }
  lb_rules                   = false == var.enable_internal_loadbalancer ? {} : var.lb_enable_ha_ports && var.lb_sku == "Standard" && length(var.lb_rules) > 0 ? { "all_0" = local.transform_lb_probes[0] } : local.transform_lb_rules
  ip_address                 = { for i in local.virtual_machine_name : i => cidrhost(var.subnet_resource["address_prefixes"][0], index(local.virtual_machine_name, i) + var.vm_starting_ip) if var.vm_starting_ip != null }
  marketplace_image          = var.plan_name != "" || var.plan_publisher != "" || var.plan_product != "" ? [""] : []
  resource_group_name        = var.resource_group_resource["name"]
  location                   = coalesce(var.location, var.resource_group_resource["location"])
  os_type                    = coalesce(var.os_type, length(regexall("\\w*([Ww]indows|[Vv]isual[Ss]tudio)\\w*", var.image_offer)) > 0 ? "windows" : "linux")
}

resource "azurerm_marketplace_agreement" "this" {
  count = length(local.marketplace_image)

  publisher = var.plan_publisher
  offer     = var.plan_product
  plan      = var.plan_name
}

resource "azurerm_availability_set" "this" {
  count = var.enable_availability_set ? 1 : 0

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
  request_path        = contains(["Https", "Http"], split("_", each.value)[0]) ? "/" : null
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

resource "azurerm_network_interface" "this" {
  for_each = toset(local.virtual_machine_name)

  name                = format("%s%s", each.key, var.network_interface_suffix)
  location            = local.location
  resource_group_name = local.resource_group_name
  dns_servers         = var.dns_servers

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = var.subnet_resource["id"]
    private_ip_address_allocation = var.vm_starting_ip == null ? "Dynamic" : "Static"
    private_ip_address            = var.vm_starting_ip == null ? null : local.ip_address[each.key]
  }

  tags = merge(
    var.tags,
    {
      "resource" = "network interface"
    },
  )

  depends_on = [var.module_depends_on]
}

resource "azurerm_network_interface_backend_address_pool_association" "this" {
  for_each = var.enable_lb_backend_address_pool_association ? toset(local.virtual_machine_name) : []

  network_interface_id    = azurerm_network_interface.this[each.key].id
  ip_configuration_name   = azurerm_network_interface.this[each.key].ip_configuration[0].name
  backend_address_pool_id = local.lb_backend_address_pool_id
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

resource "azurerm_managed_disk" "this" {
  for_each = local.data_disk

  name                 = format("%s%s", replace(each.key, "_", "-"), var.data_disk_suffix)
  location             = local.location
  resource_group_name  = local.resource_group_name
  storage_account_type = each.value["type"]
  create_option        = "Empty"
  disk_size_gb         = each.value["size"]

  tags = merge(
    var.tags,
    {
      "resource" = "managed disk"
    },
  )
}

resource "azurerm_windows_virtual_machine" "this" {
  for_each = local.os_type == "windows" ? toset(local.virtual_machine_name) : []

  name                       = each.key
  location                   = local.location
  resource_group_name        = local.resource_group_name
  network_interface_ids      = [azurerm_network_interface.this[each.key].id]
  availability_set_id        = local.availability_set_id
  size                       = var.vm_size
  computer_name              = each.key
  admin_username             = var.admin_username
  admin_password             = var.admin_password
  timezone                   = var.timezone
  license_type               = var.license_type
  priority                   = var.priority
  max_bid_price              = var.priority == "Spot" ? var.max_bid_price : null
  eviction_policy            = var.priority == "Spot" ? var.eviction_policy : null
  provision_vm_agent         = true
  enable_automatic_updates   = var.patch_mode != "Manual"
  patch_mode                 = var.patch_mode
  allow_extension_operations = var.allow_extension_operations

  dynamic "boot_diagnostics" {
    for_each = local.boot_diag_stor_blob_ep != null ? [local.boot_diag_stor_blob_ep] : []

    content {
      storage_account_uri = boot_diagnostics.value
    }
  }

  dynamic "identity" {
    for_each = var.create_system_assigned_identity || length(var.user_assigned_identity_ids) > 0 ? [""] : []

    content {
      type         = var.create_system_assigned_identity && length(var.user_assigned_identity_ids) > 0 ? "SystemAssigned, UserAssigned" : var.create_system_assigned_identity ? "SystemAssigned" : "UserAssigned"
      identity_ids = length(var.user_assigned_identity_ids) > 0 ? var.user_assigned_identity_ids : null
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

  os_disk {
    name                 = format("%s%s", each.key, var.os_disk_suffix)
    caching              = "ReadWrite"
    storage_account_type = var.os_managed_disk_type
    disk_size_gb         = var.disk_size_gb
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
          url   = certificate.value
          store = var.certificate_store_name
        }
      }
    }
  }

  tags = merge(
    var.tags,
    {
      "resource" = "virtual machine"
    },
  )

  depends_on = [azurerm_marketplace_agreement.this]

  lifecycle {
    ignore_changes = [timezone]
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  for_each = local.os_type == "windows" ? [] : toset(local.virtual_machine_name)

  name                            = each.key
  location                        = local.location
  resource_group_name             = local.resource_group_name
  network_interface_ids           = [azurerm_network_interface.this[each.key].id]
  availability_set_id             = local.availability_set_id
  size                            = var.vm_size
  computer_name                   = each.key
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  priority                        = var.priority
  max_bid_price                   = var.priority == "Spot" ? var.max_bid_price : null
  eviction_policy                 = var.priority == "Spot" ? var.eviction_policy : null
  disable_password_authentication = var.admin_password == null
  provision_vm_agent              = true
  allow_extension_operations      = var.allow_extension_operations

  dynamic "boot_diagnostics" {
    for_each = local.boot_diag_stor_blob_ep != null ? [local.boot_diag_stor_blob_ep] : []

    content {
      storage_account_uri = boot_diagnostics.value
    }
  }

  dynamic "identity" {
    for_each = var.create_system_assigned_identity || length(var.user_assigned_identity_ids) > 0 ? [""] : []

    content {
      type         = var.create_system_assigned_identity && length(var.user_assigned_identity_ids) > 0 ? "SystemAssigned, UserAssigned" : var.create_system_assigned_identity ? "SystemAssigned" : "UserAssigned"
      identity_ids = length(var.user_assigned_identity_ids) > 0 ? var.user_assigned_identity_ids : null
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

  os_disk {
    name                 = format("%s%s", each.key, var.os_disk_suffix)
    caching              = "ReadWrite"
    storage_account_type = var.os_managed_disk_type
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  dynamic "admin_ssh_key" {
    for_each = var.admin_password != null ? [] : var.ssh_keys

    content {
      public_key = admin_ssh_key.value
      username   = var.admin_username
    }
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

  tags = merge(
    var.tags,
    {
      "resource" = "virtual machine"
    },
  )

  depends_on = [azurerm_marketplace_agreement.this]
}

resource "azurerm_virtual_machine_data_disk_attachment" "this" {
  for_each = local.data_disk

  managed_disk_id    = azurerm_managed_disk.this[each.key].id
  virtual_machine_id = local.os_type == "windows" ? azurerm_windows_virtual_machine.this[split("_", each.key)[0]].id : azurerm_linux_virtual_machine.this[split("_", each.key)[0]].id
  lun                = each.value["lun"]
  caching            = each.value["caching"]
}
