resource "azurerm_subnet" "this" {
  name                 = "${local.deprecated_prefix}-codingcenter-as-subnet"
  virtual_network_name = data.terraform_remote_state.nonprod_shared.outputs.vnet.name
  resource_group_name  = data.terraform_remote_state.nonprod_shared.outputs.vnet.resource_group_name
  address_prefixes     = var.subnet_address_prefixes

  delegation {
    name = "Microsoft.Web.serverFarms"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_network_security_group" "this" {
  name                = "${local.deprecated_prefix}-codingcenter-as-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = merge(
    local.tags,
    {
      "resource" = "network security group"
    },
  )
}

resource "azurerm_monitor_diagnostic_setting" "network_security_group" {
  name                       = "SendAllToLogAnalytics"
  target_resource_id         = azurerm_network_security_group.this.id
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

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = azurerm_subnet.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}
