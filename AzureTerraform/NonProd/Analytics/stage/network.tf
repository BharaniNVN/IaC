resource "azurerm_subnet" "analytics" {
  name                 = "${local.deprecated_prefix}-subnet"
  virtual_network_name = data.terraform_remote_state.nonprod_shared.outputs.vnet.name
  resource_group_name  = data.terraform_remote_state.nonprod_shared.outputs.vnet.resource_group_name
  address_prefixes     = ["10.105.132.96/27"]
  service_endpoints    = ["Microsoft.Sql", "Microsoft.AzureActiveDirectory", "Microsoft.KeyVault", "Microsoft.Storage"]
}

resource "azurerm_network_security_group" "analytics" {
  name                = "${local.deprecated_prefix}-nsg"
  location            = azurerm_resource_group.analytics.location
  resource_group_name = azurerm_resource_group.analytics.name

  tags = merge(
    local.tags,
    {
      "resource" = "network security group"
    },
  )
}

resource "azurerm_subnet_network_security_group_association" "analytics" {
  subnet_id                 = azurerm_subnet.analytics.id
  network_security_group_id = azurerm_network_security_group.analytics.id
}

resource "azurerm_subnet_route_table_association" "this" {
  subnet_id      = azurerm_subnet.analytics.id
  route_table_id = data.terraform_remote_state.nonprod_shared.outputs.fw_rt_id
}

resource "azurerm_monitor_diagnostic_setting" "analytics_stage_paas_nsg" {
  name               = "SendAllToLogAnalytics"
  target_resource_id = azurerm_network_security_group.analytics.id

  log_analytics_workspace_id = data.terraform_remote_state.nonprod_shared.outputs.log_analytics.id

  dynamic "log" {
    for_each = ["NetworkSecurityGroupEvent", "NetworkSecurityGroupRuleCounter"]

    content {
      category = log.value

      retention_policy {
        enabled = false
      }
    }
  }
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
    source_addresses      = azurerm_subnet.analytics.address_prefixes
    destination_ports     = ["587", "465"]
    destination_addresses = ["*"]
    protocols             = ["TCP"]
  }
}
