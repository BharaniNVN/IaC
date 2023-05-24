resource "azurerm_subnet" "this" {
  name                 = "${local.prefix}-subnet"
  virtual_network_name = data.terraform_remote_state.nonprod_shared.outputs.vnet.name
  resource_group_name  = data.terraform_remote_state.nonprod_shared.outputs.vnet.resource_group_name
  address_prefixes     = ["10.105.139.0/27"]
}

resource "azurerm_subnet_route_table_association" "this" {
  subnet_id      = azurerm_subnet.this.id
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
    name                  = "sftp-hc3"
    source_addresses      = module.build.ip_address
    destination_ports     = ["22"]
    destination_addresses = data.terraform_remote_state.nonprod_shared.outputs.sftp_ip_addresses["hc3"]
    protocols             = ["TCP"]
  }

  rule {
    name                  = "sftp-tellus"
    source_addresses      = concat(module.build.ip_address, module.app.ip_address)
    destination_ports     = ["22"]
    destination_addresses = var.pd_sftp_tellus
    protocols             = ["TCP"]
  }
  
  rule {
    name                  = "sendgrid"
    source_addresses      = concat(module.app.ip_address, module.sql.ip_address, module.web.ip_address, module.build.ip_address, module.ssrs.ip_address)
    destination_ports     = ["587", "465"]
    destination_addresses = ["*"]
    protocols             = ["TCP"]
  }

  rule {
    name                  = "sftp-triton"
    source_addresses      = concat(module.web.ip_address)
    destination_ports     = ["9200", "50000-51000"]
    destination_addresses = [var.sftp_triton_dest_ip]
    protocols             = ["TCP"]
  }

  rule {
    name                  = "ftps-soneto"
    source_addresses      = concat(module.build.ip_address, module.app.ip_address)
    destination_ports     = ["22", "990", "29900-30000"]
    destination_addresses = [var.ftps_soneto_dest_ip]
    protocols             = ["TCP"]
  }

    rule {
    name                  = "alvaria-inbound"
    source_addresses      = var.alvaria_inbound
    destination_ports     = ["*"]
    destination_addresses = concat(module.web.ip_address)
    protocols             = ["TCP"]
  }

    rule {
    name                  = "outbound-allow"
    source_addresses      = concat(module.app.ip_address, module.sql.ip_address, module.web.ip_address, module.build.ip_address, module.ssrs.ip_address)
    destination_ports     = ["*"]
    destination_addresses = ["*"]
    protocols             = ["TCP"]
  }

}
