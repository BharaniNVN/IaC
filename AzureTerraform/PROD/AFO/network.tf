# resource "random_integer" "azurerm_firewall_network_rule_collection_priority" {
#   min = split("-", data.terraform_remote_state.prod_shared.outputs.azure_firewall_rule_collection_priority_ranges[lower(var.environment)])[0]
#   max = split("-", data.terraform_remote_state.prod_shared.outputs.azure_firewall_rule_collection_priority_ranges[lower(var.environment)])[1]
# }

# resource "azurerm_firewall_network_rule_collection" "this" {
#   name                = format("%s-rules", local.prefix)
#   azure_firewall_name = data.terraform_remote_state.shared.outputs.fw.name
#   resource_group_name = data.terraform_remote_state.shared.outputs.fw.resource_group_name
#   priority            = random_integer.azurerm_firewall_network_rule_collection_priority.result
#   action              = "Allow"

#   rule {
#     name                  = "sendgrid"
#     source_addresses      = concat(module.oracle7.ip_address, module.sql7.ip_address)
#     destination_ports     = ["587", "465"]
#     destination_addresses = ["*"]
#     protocols             = ["TCP"]
#   }

# #   rule {
# #     name                  = "sftp-capario"
# #     source_addresses      = module.wf.ip_address
# #     destination_ports     = ["22"]
# #     destination_addresses = data.terraform_remote_state.prod_shared.outputs.sftp_ip_addresses["capario"]
# #     protocols             = ["TCP"]
# #   }

#   rule {
#     name                  = "sftp-deyta"
#     source_addresses      = concat(module.afo7.ip_address, module.app7.ip_address)
#     destination_ports     = ["22"]
#     destination_addresses = data.terraform_remote_state.prod_shared.outputs.sftp_ip_addresses["deyta"]
#     protocols             = ["TCP"]
#   }

#   rule {
#     name = "sftp-rs"
#     source_addresses = module.app7.ip_address
#     destination_ports     = ["22"]
#     destination_addresses = data.terraform_remote_state.prod_shared.outputs.sftp_ip_addresses["rs"]
#     protocols             = ["TCP"]
#   }

#   rule {
#     name = "sftp-tellus"
#     source_addresses = concat(
#       module.afo7.ip_address,
#       module.app7.ip_address,
#     )
#     destination_ports     = ["22"]
#     destination_addresses = data.terraform_remote_state.prod_shared.outputs.sftp_ip_addresses["tellus"]
#     protocols             = ["TCP"]
#   }

# #   rule {
# #     name                  = "sftp-waystar"
# #     source_addresses      = module.wf.ip_address
# #     destination_ports     = ["22"]
# #     destination_addresses = data.terraform_remote_state.prod_shared.outputs.sftp_ip_addresses["waystar"]
# #     protocols             = ["TCP"]
# #   }
# }
