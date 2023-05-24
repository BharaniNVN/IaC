resource "azurerm_virtual_network" "hub_vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = [var.hub_vnet_address_space]
  location            = azurerm_resource_group.fw_rg.location
  resource_group_name = azurerm_resource_group.fw_rg.name

  tags = merge(
    local.tags,
    {
      "resource" = "virtual network"
    },
  )
}

resource "azurerm_subnet" "azure_firewall_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.fw_rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = [var.hub_fw_subnet_address_space]
}

resource "azurerm_virtual_network_peering" "to_cusupvnt01" {
  name                         = "to_cusupvnt01"
  resource_group_name          = azurerm_resource_group.fw_rg.name
  virtual_network_name         = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id    = "/subscriptions/${var.cusupvnt01_subscription_id}/resourceGroups/${var.cusupvnt01_resource_group_name}/providers/Microsoft.Network/virtualNetworks/${var.cusupvnt01_name}"
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "hub_to_pipelines_agent" {
  name                         = "hub-to-pipelines-agent"
  resource_group_name          = azurerm_resource_group.fw_rg.name
  virtual_network_name         = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id    = join("/", slice(split("/", local.pipelines_agent_subnet_resource.id), 0, 9))
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "pipelines_agent_to_hub" {
  name                         = "pipelines-agent-to-hub"
  resource_group_name          = local.pipelines_agent_subnet_resource.resource_group_name
  virtual_network_name         = local.pipelines_agent_subnet_resource.virtual_network_name
  remote_virtual_network_id    = azurerm_virtual_network.hub_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_route_table" "pipelines_agent" {
  name                          = "pipelines-agent-rt"
  location                      = local.pipelines_agent_subnet_resource.location
  resource_group_name           = local.pipelines_agent_subnet_resource.resource_group_name
  disable_bgp_route_propagation = false

  route {
    name                   = "route-to-azure-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub_fw.ip_configuration[0].private_ip_address
  }

  tags = merge(
    local.tags,
    {
      "resource" = "route table"
    },
  )
}

resource "azurerm_subnet_route_table_association" "pipelines_agent" {
  subnet_id      = local.pipelines_agent_subnet_resource.id
  route_table_id = azurerm_route_table.pipelines_agent.id
}
