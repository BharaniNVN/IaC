resource "azurerm_resource_group" "network" {
  name     = "${local.deprecated_prefix}-network-rg"
  location = var.location

  tags = merge(
    local.tags,
    {
      "resource" = "resource group"
    },
  )
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${local.deprecated_prefix}-vnet"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  address_space       = ["10.105.0.0/19"]

  tags = merge(
    local.tags,
    {
      "resource" = "virtual network"
    },
  )
}

resource "azurerm_subnet" "gateway_subnet" {
  name                 = "GatewaySubnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.network.name
  address_prefixes     = ["10.105.0.96/27"]
}

resource "azurerm_subnet" "wafsubnet" {
  name                 = "WafSubnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.network.name
  service_endpoints    = ["Microsoft.Web"]
  address_prefixes     = ["10.105.0.64/27"]
}

resource "azurerm_subnet" "dmz_subnet" {
  name                                           = "DMZ"
  virtual_network_name                           = azurerm_virtual_network.vnet.name
  resource_group_name                            = azurerm_resource_group.network.name
  address_prefixes                               = ["10.105.2.0/24"]
  service_endpoints                              = ["Microsoft.Storage"]
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_subnet" "cawprod_subnet" {
  name                                           = "Internal"
  virtual_network_name                           = azurerm_virtual_network.vnet.name
  resource_group_name                            = azurerm_resource_group.network.name
  address_prefixes                               = ["10.105.3.0/24"]
  enforce_private_link_endpoint_network_policies = true
  service_endpoints                              = ["Microsoft.Storage"]
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.105.0.128/27"]
}

resource "azurerm_public_ip" "bastion" {
  name                = "${local.deprecated_prefix}-bastion-pip"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(
    local.tags,
    {
      "resource" = "public ip"
    },
  )
}

resource "azurerm_public_ip" "er_gateway" {
  name                = "${local.deprecated_prefix}-er-gw-pip"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  allocation_method   = "Dynamic"

  tags = merge(
    local.tags,
    {
      "resource" = "public ip"
    },
  )
}

resource "azurerm_virtual_network_gateway" "er_gateway" {
  name                = "${local.deprecated_prefix}-er-gw"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name

  type     = "ExpressRoute"
  vpn_type = var.er_type

  active_active = false
  enable_bgp    = false
  sku           = var.er_sku

  ip_configuration {
    name                          = "gatewayIPConfig1"
    public_ip_address_id          = azurerm_public_ip.er_gateway.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway_subnet.id
  }

  tags = merge(
    local.tags,
    {
      "resource" = "virtual network gateway"
    },
  )
}

resource "azurerm_virtual_network_gateway_connection" "er_to_onprem" {
  name                = "${local.deprecated_prefix}-er-gw-connection"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name

  type                       = "ExpressRoute"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.er_gateway.id
  express_route_circuit_id   = var.express_route_circuit_id

  routing_weight                     = 10
  enable_bgp                         = false
  express_route_gateway_bypass       = false
  use_policy_based_traffic_selectors = false

  tags = merge(
    local.tags,
    {
      "resource" = "virtual network gateway connection"
    },
  )
}

resource "azurerm_virtual_network_peering" "prod_to_hub" {
  name                         = "prod-to-hub"
  resource_group_name          = azurerm_resource_group.network.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = data.terraform_remote_state.shared.outputs.fw_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "hub_to_prod" {
  name                         = "hub-to-prod"
  resource_group_name          = data.terraform_remote_state.shared.outputs.fw_vnet.resource_group_name
  virtual_network_name         = data.terraform_remote_state.shared.outputs.fw_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "prod_to_mx_shared" {
  name                         = "prod-to-shared"
  resource_group_name          = azurerm_resource_group.network.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = "/subscriptions/414c73a5-4146-477f-a813-8a1e20dabc33/resourceGroups/CUSSHRSGSH01/providers/Microsoft.Network/virtualNetworks/CUSSHVNT01"
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_route_table" "prod_rt" {
  name                          = "prod-rt"
  location                      = azurerm_resource_group.network.location
  resource_group_name           = azurerm_resource_group.network.name
  disable_bgp_route_propagation = false

  route {
    name                   = "route-to-fw"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = data.terraform_remote_state.shared.outputs.fw.ip_configuration[0].private_ip_address
  }

  route {
    name                   = "route-to-GlobalProtect"
    address_prefix         = "10.223.8.0/24"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.223.4.100"
  }

  tags = merge(
    local.tags,
    {
      "resource" = "route table"
    },
  )
}

resource "azurerm_subnet_route_table_association" "prod_shared_subnets_to_rt_associations" {
  for_each = local.subnets

  subnet_id      = each.value
  route_table_id = azurerm_route_table.prod_rt.id
}

module "file" {
  source = "../../../modules/terraform/private_endpoint"

  resource_group_resource = azurerm_resource_group.resources
  subnet_resource         = azurerm_subnet.cawprod_subnet
  resource                = azurerm_storage_account.ops
  endpoint                = "file"
  ip_index                = 10
  tags                    = local.tags
}

resource "random_integer" "azurerm_firewall_network_rule_collection_priority" {
  min = split("-", data.terraform_remote_state.shared.outputs.azure_firewall_rule_collection_priority_ranges[lower(format("%s_%s", var.application, var.environment))])[0]
  max = split("-", data.terraform_remote_state.shared.outputs.azure_firewall_rule_collection_priority_ranges[lower(format("%s_%s", var.application, var.environment))])[1]
}

resource "azurerm_firewall_network_rule_collection" "this" {
  name                = format("%s-rules", local.prefix)
  azure_firewall_name = data.terraform_remote_state.shared.outputs.fw.name
  resource_group_name = data.terraform_remote_state.shared.outputs.fw.resource_group_name
  priority            = random_integer.azurerm_firewall_network_rule_collection_priority.result
  action              = "Allow"

  rule {
    name                  = "sendgrid"
    source_addresses      = module.client_purge_sql.ip_address
    destination_ports     = ["587", "465"]
    destination_addresses = ["*"]
    protocols             = ["TCP"]
  }
}
