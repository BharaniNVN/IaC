locals {
  resource_group_name              = var.resource_group_resource["name"]
  location                         = coalesce(var.location, var.resource_group_resource["location"])
  virtual_machine                  = module.virtual_machine.id
  awx_database_server_azure_name   = format("%s%s", var.resource_prefix, var.awx_database_server_azure_suffix)
  awx_database_server_fqdn         = var.awx_database_server_type == "External" ? var.awx_database_server_external_name : var.awx_database_server_type == "Azure" ? azurerm_private_endpoint.this[0].private_service_connection[0].private_ip_address : format("%s.postgres.database.azure.com", local.awx_database_server_azure_name)
  awx_database_server_username     = var.awx_database_server_type == "Azure" ? format("%s@%s", var.awx_database_server_username, local.awx_database_server_azure_name) : var.awx_database_server_username
  subnet_name                      = split("/", var.subnet_resource.id)[10]
  network_name                     = split("/", var.subnet_resource.id)[8]
  postgresql_private_endpoint_name = format("%s-pe", local.awx_database_server_azure_name)
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
  image_offer                                = var.image_offer
  image_publisher                            = var.image_publisher
  image_sku                                  = var.image_sku
  image_version                              = var.image_version
  os_disk_suffix                             = var.os_disk_suffix
  os_managed_disk_type                       = var.os_managed_disk_type
  admin_username                             = var.admin_username
  admin_password                             = var.admin_password
  create_system_assigned_identity            = var.create_system_assigned_identity
  tags                                       = var.tags
  user_assigned_identity_ids                 = var.user_assigned_identity_ids
  module_depends_on                          = var.module_depends_on
}

resource "azurerm_virtual_machine_extension" "custom_script" {
  for_each = toset(module.virtual_machine.name)

  name                 = "awx"
  virtual_machine_id   = local.virtual_machine[each.value]
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = var.custom_script_extension_version

  settings = <<SETTINGS
    {
      "script": "${base64encode(data.template_file.custom_script.rendered)}"
    }
  SETTINGS
}

resource "azurerm_postgresql_server" "this" {
  count = var.awx_database_server_type == "Azure" ? 1 : 0

  name                         = local.awx_database_server_azure_name
  location                     = local.location
  resource_group_name          = local.resource_group_name
  sku_name                     = var.awx_database_server_azure_sku_name
  administrator_login          = var.awx_database_server_username
  administrator_login_password = var.awx_database_server_password
  version                      = var.awx_database_server_azure_version
  create_mode                  = "Default"
  ssl_enforcement_enabled      = var.awx_database_server_azure_ssl_enforcement
  storage_mb                   = var.awx_database_server_azure_storage_mb
  backup_retention_days        = var.awx_database_server_azure_backup_retention_days
  geo_redundant_backup_enabled = var.awx_database_server_azure_geo_redundant_backup
  auto_grow_enabled            = var.awx_database_server_azure_auto_grow

  tags = merge(
    var.tags,
    {
      "resource" = "postgresql server"
    },
  )
}

resource "azurerm_postgresql_database" "this" {
  count = var.awx_database_server_type == "Azure" ? 1 : 0

  name                = var.awx_database_name
  resource_group_name = local.resource_group_name
  server_name         = azurerm_postgresql_server.this[0].name
  charset             = var.awx_database_azure_charset
  collation           = var.awx_database_azure_collation
}

resource "azurerm_private_endpoint" "this" {
  count = var.awx_database_server_type == "Azure" ? 1 : 0

  name                = local.postgresql_private_endpoint_name
  location            = local.location
  resource_group_name = local.resource_group_name
  subnet_id           = var.endpoint_subnet_resource.id

  private_service_connection {
    name                           = "${local.awx_database_server_azure_name}-psc"
    private_connection_resource_id = azurerm_postgresql_server.this[0].id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }

  tags = merge(
    var.tags,
    {
      "resource" = "private endpoint"
    },
  )
}

resource "azurerm_postgresql_active_directory_administrator" "this" {
  count = var.awx_database_server_type == "Azure" && var.azuread_sql_admins_group != null ? 1 : 0

  server_name         = azurerm_postgresql_server.this[0].name
  resource_group_name = local.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  login               = var.azuread_sql_admins_group.name
  object_id           = var.azuread_sql_admins_group.object_id
}
