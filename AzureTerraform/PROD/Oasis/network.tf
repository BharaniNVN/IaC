resource "azurerm_subnet" "app_service" {
  name                 = "${local.deprecated_prefix}-oasis-as-subnet"
  virtual_network_name = data.terraform_remote_state.prod_shared.outputs.vnet.name
  resource_group_name  = data.terraform_remote_state.prod_shared.outputs.vnet.resource_group_name
  address_prefixes     = ["10.105.4.0/26"]
  service_endpoints    = ["Microsoft.AzureCosmosDB"]

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_network_security_group" "app_service" {
  name                = "${local.deprecated_prefix}-oasis-as-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = merge(
    local.tags,
    {
      "resource" = "network security group"
    }
  )
}

resource "azurerm_monitor_diagnostic_setting" "network_security_group_app_service" {
  name               = "SendAllToLogAnalytics"
  target_resource_id = azurerm_network_security_group.app_service.id

  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

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

resource "azurerm_subnet_network_security_group_association" "app_service" {
  subnet_id                 = azurerm_subnet.app_service.id
  network_security_group_id = azurerm_network_security_group.app_service.id
}

resource "azurerm_subnet" "paas" {
  name                 = "${local.deprecated_prefix}-oasis-paas-subnet"
  virtual_network_name = data.terraform_remote_state.prod_shared.outputs.vnet.name
  resource_group_name  = data.terraform_remote_state.prod_shared.outputs.vnet.resource_group_name
  address_prefixes     = ["10.105.4.64/26"]
  service_endpoints    = ["Microsoft.AzureCosmosDB", "Microsoft.Sql", "Microsoft.ServiceBus", "Microsoft.AzureActiveDirectory", "Microsoft.Storage"]
}

resource "azurerm_network_security_group" "paas" {
  name                = "${local.deprecated_prefix}-oasis-paas-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  tags = merge(
    local.tags,
    {
      "resource" = "network security group"
    }
  )
}

resource "azurerm_monitor_diagnostic_setting" "network_security_group_paas" {
  name               = "SendAllToLogAnalytics"
  target_resource_id = azurerm_network_security_group.paas.id

  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

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
