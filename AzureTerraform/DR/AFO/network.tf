resource "random_integer" "azurerm_firewall_network_rule_collection_priority" {
  min = split("-", data.terraform_remote_state.dr_shared.outputs.azure_firewall_rule_collection_priority_ranges[lower(var.environment)])[0]
  max = split("-", data.terraform_remote_state.dr_shared.outputs.azure_firewall_rule_collection_priority_ranges[lower(var.environment)])[1]
}

resource "azurerm_firewall_network_rule_collection" "this" {
  name                = format("%s-rules", local.prefix)
  azure_firewall_name = data.terraform_remote_state.dr_shared.outputs.azure_firewall_resource.name
  resource_group_name = data.terraform_remote_state.dr_shared.outputs.azure_firewall_resource.resource_group_name
  priority            = random_integer.azurerm_firewall_network_rule_collection_priority.result
  action              = "Allow"

  rule {
    name = "sendgrid"
    source_addresses = concat(
      module.oracle2.ip_address,
      module.oracle4.ip_address,
      module.oracle5.ip_address,
      module.oracle6.ip_address,
      module.oracle7.ip_address,
      module.oracle8.ip_address,
      module.sql2.ip_address,
      module.sql4.ip_address,
      module.sql5.ip_address,
      module.sql6.ip_address,
      module.sql7.ip_address,
      module.sql8.ip_address,
      module.sql_shared.ip_address,
    )
    destination_ports     = ["587", "465"]
    destination_addresses = ["*"]
    protocols             = ["TCP"]
  }

  rule {
    name                  = "sftp-capario"
    source_addresses      = module.wf.ip_address
    destination_ports     = ["22"]
    destination_addresses = data.terraform_remote_state.dr_shared.outputs.sftp_ip_addresses["capario"]
    protocols             = ["TCP"]
  }

  rule {
    name = "sftp-deyta"
    source_addresses = concat(
      module.afo2.ip_address,
      module.afo4.ip_address,
      module.afo5.ip_address,
      module.afo6.ip_address,
      module.afo7.ip_address,
      module.afo8.ip_address,
      module.app2.ip_address,
      module.app4.ip_address,
      module.app5.ip_address,
      module.app6.ip_address,
      module.app7.ip_address,
      module.app8.ip_address,
    )
    destination_ports     = ["22"]
    destination_addresses = data.terraform_remote_state.dr_shared.outputs.sftp_ip_addresses["deyta"]
    protocols             = ["TCP"]
  }

  rule {
    name = "sftp-rs"
    source_addresses = concat(
      module.app2.ip_address,
      module.app4.ip_address,
      module.app5.ip_address,
      module.app6.ip_address,
      module.app7.ip_address,
      module.app8.ip_address,
    )
    destination_ports     = ["22"]
    destination_addresses = data.terraform_remote_state.dr_shared.outputs.sftp_ip_addresses["rs"]
    protocols             = ["TCP"]
  }

  rule {
    name = "sftp-tellus"
    source_addresses = concat(
      module.afo2.ip_address,
      module.afo4.ip_address,
      module.afo5.ip_address,
      module.afo6.ip_address,
      module.afo7.ip_address,
      module.afo8.ip_address,
      module.app2.ip_address,
      module.app4.ip_address,
      module.app5.ip_address,
      module.app6.ip_address,
      module.app7.ip_address,
      module.app8.ip_address,
    )
    destination_ports     = ["22"]
    destination_addresses = data.terraform_remote_state.dr_shared.outputs.sftp_ip_addresses["tellus"]
    protocols             = ["TCP"]
  }

  rule {
    name                  = "sftp-waystar"
    source_addresses      = module.wf.ip_address
    destination_ports     = ["22"]
    destination_addresses = data.terraform_remote_state.dr_shared.outputs.sftp_ip_addresses["waystar"]
    protocols             = ["TCP"]
  }
}
