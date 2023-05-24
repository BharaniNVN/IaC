resource "azurerm_subnet" "paas" {
  name                 = "${local.deprecated_prefix}-codingcenter-paas-subnet"
  virtual_network_name = data.terraform_remote_state.nonprod_shared.outputs.vnet.name
  resource_group_name  = data.terraform_remote_state.nonprod_shared.outputs.vnet.resource_group_name
  address_prefixes     = var.subnet_address_prefixes
  service_endpoints    = data.terraform_remote_state.nonprod_shared.outputs.service_endpoints
}

resource "azurerm_network_security_group" "paas" {
  name                = "${local.deprecated_prefix}-codingcenter-paas-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = merge(
    local.tags,
    {
      "resource" = "network security group"
    },
  )
}

resource "azurerm_monitor_diagnostic_setting" "network_security_group_paas" {
  name                       = "SendAllToLogAnalytics"
  target_resource_id         = azurerm_network_security_group.paas.id
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

resource "azurerm_subnet_network_security_group_association" "paas" {
  subnet_id                 = azurerm_subnet.paas.id
  network_security_group_id = azurerm_network_security_group.paas.id
}
