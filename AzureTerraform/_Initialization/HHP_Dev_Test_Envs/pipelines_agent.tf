resource "azurerm_resource_group" "pipelines_agent" {
  name     = format("%spipelinesagent-rg", lower(var.env))
  location = var.location

  tags = merge(
    local.tags,
    {
      "resource" = "resource group"
    },
  )
}

resource "azurerm_virtual_network" "pipelines_agent" {
  name                = format("%spipelinesagent-vnet", lower(var.env))
  address_space       = var.pipelines_agent_virtual_network_address_space
  location            = azurerm_resource_group.pipelines_agent.location
  resource_group_name = azurerm_resource_group.pipelines_agent.name
  dns_servers         = ["10.105.128.165","10.105.128.166"]

  tags = merge(
    local.tags,
    {
      "resource" = "virtual network"
    },
  )
}

resource "azurerm_subnet" "pipelines_agent_aci" {
  name                 = "pipelinesagentaci-subnet"
  resource_group_name  = azurerm_resource_group.pipelines_agent.name
  virtual_network_name = azurerm_virtual_network.pipelines_agent.name
  address_prefixes     = var.pipelines_agent_subnet_address_space
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "Microsoft.ContainerInstance.containerGroups"

    service_delegation {
      name = "Microsoft.ContainerInstance/containerGroups"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
    }
  }
}
