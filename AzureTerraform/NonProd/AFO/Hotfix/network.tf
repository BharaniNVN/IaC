resource "azurerm_subnet" "internal" {
  name                 = "${local.prefix}-internal"
  virtual_network_name = data.terraform_remote_state.nonprod_shared.outputs.vnet.name
  resource_group_name  = data.terraform_remote_state.nonprod_shared.outputs.vnet.resource_group_name
  address_prefixes     = ["10.105.130.64/27"]
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_subnet" "dmz" {
  name                                           = "${local.prefix}-dmz"
  virtual_network_name                           = data.terraform_remote_state.nonprod_shared.outputs.vnet.name
  resource_group_name                            = data.terraform_remote_state.nonprod_shared.outputs.vnet.resource_group_name
  address_prefixes                               = ["10.105.130.96/27"]
  service_endpoints                              = ["Microsoft.Storage"]
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_subnet_route_table_association" "this" {
  for_each = local.subnets

  subnet_id      = each.value
  route_table_id = data.terraform_remote_state.nonprod_shared.outputs.fw_rt_id
}

resource "random_integer" "azurerm_firewall_network_rule_collection_priority" {
  min = split("-", data.terraform_remote_state.nonprod_shared.outputs.azure_firewall_rule_collection_priority_ranges[lower(var.environment)])[0]
  max = split("-", data.terraform_remote_state.nonprod_shared.outputs.azure_firewall_rule_collection_priority_ranges[lower(var.environment)])[1]
}

resource "azurerm_firewall_network_rule_collection" "this" {
  name                = format("%s-rules", local.prefix)
  azure_firewall_name = data.terraform_remote_state.nonprod_shared.outputs.fw.name
  resource_group_name = data.terraform_remote_state.nonprod_shared.outputs.fw.resource_group_name
  priority            = random_integer.azurerm_firewall_network_rule_collection_priority.result
  action              = "Allow"

  rule {
    name                  = "sendgrid"
    source_addresses      = concat(module.oracle.ip_address, module.sql.ip_address, module.sql_shared.ip_address)
    destination_ports     = ["587", "465"]
    destination_addresses = ["*"]
    protocols             = ["TCP"]
  }

  rule {
    name                  = "sftp-capario"
    source_addresses      = module.wf.ip_address
    destination_ports     = ["22"]
    destination_addresses = var.sftp_capario_ip_address
    protocols             = ["TCP"]
  }

  rule {
    name                  = "sftp-deyta"
    source_addresses      = concat(module.afo.ip_address, module.app.ip_address)
    destination_ports     = ["22"]
    destination_addresses = data.terraform_remote_state.nonprod_shared.outputs.sftp_ip_addresses["deyta"]
    protocols             = ["TCP"]
  }

  rule {
    name                  = "sftp-matrixcarehhp"
    source_addresses      = concat(module.afo.ip_address, module.app.ip_address, module.hhpque.ip_address, module.oracle.ip_address)
    destination_ports     = ["22"]
    destination_addresses = data.terraform_remote_state.nonprod_shared.outputs.sftp_ip_addresses["matrixcarehhp"]
    protocols             = ["TCP"]
  }

  rule {
    name                  = "sftp-rs"
    source_addresses      = module.app.ip_address
    destination_ports     = ["22"]
    destination_addresses = data.terraform_remote_state.nonprod_shared.outputs.sftp_ip_addresses["rs"]
    protocols             = ["TCP"]
  }

  rule {
    name                  = "sftp-tellus"
    source_addresses      = concat(module.afo.ip_address, module.app.ip_address)
    destination_ports     = ["22"]
    destination_addresses = data.terraform_remote_state.nonprod_shared.outputs.sftp_ip_addresses["tellus"]
    protocols             = ["TCP"]
  }

  rule {
    name                  = "sftp-waystar"
    source_addresses      = module.wf.ip_address
    destination_ports     = ["22"]
    destination_addresses = data.terraform_remote_state.nonprod_shared.outputs.sftp_ip_addresses["waystar"]
    protocols             = ["TCP"]
  }
}
