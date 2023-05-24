resource "azurerm_virtual_network" "vnet" {
  name                = "${local.deprecated_prefix}-vnet"
  location            = azurerm_resource_group.deprecated_rg.location
  resource_group_name = azurerm_resource_group.deprecated_rg.name
  address_space       = ["10.105.128.0/17"]
  #dns_servers         = ["10.105.68.4", "10.105.128.165"]

  tags = merge(
    local.tags,
    {
      "resource" = "virtual network"
    },
  )
}

resource "azurerm_subnet" "wafsubnet" {
  name                 = "WafSubnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.deprecated_rg.name
  service_endpoints    = ["Microsoft.Web"]
  address_prefixes     = ["10.105.128.0/27"]
}

resource "azurerm_subnet" "gatewaysubnet" {
  name                 = "GatewaySubnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.deprecated_rg.name
  address_prefixes     = ["10.105.128.64/27"]
}

resource "azurerm_subnet" "shared" {
  name                 = "shared"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.deprecated_rg.name
  address_prefixes     = ["10.105.128.160/27"]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.Sql"]
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.deprecated_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.105.128.128/27"]
}

resource "azurerm_virtual_network" "nonprod_fw_vnet" {
  name                = "${local.deprecated_prefix2}-fw-vnet"
  address_space       = ["10.105.68.0/22"]
  location            = azurerm_resource_group.fw_rg.location
  resource_group_name = azurerm_resource_group.fw_rg.name
  #dns_servers         = ["10.105.68.4", "10.105.128.165"]

  tags = merge(
    local.tags,
    {
      "resource" = "virtual network"
    },
  )
}

resource "azurerm_public_ip" "vpn_gateway" {
  name                = "${local.deprecated_prefix2}-vpn-gw-pip"
  location            = azurerm_resource_group.deprecated_rg.location
  resource_group_name = azurerm_resource_group.deprecated_rg.name
  allocation_method   = "Dynamic"

  tags = merge(
    local.tags,
    {
      "resource" = "public ip"
    },
  )
}

resource "azurerm_virtual_network_gateway" "vpn_gateway" {
  name                = "${local.deprecated_prefix2}-vpn-gw"
  location            = azurerm_resource_group.deprecated_rg.location
  resource_group_name = azurerm_resource_group.deprecated_rg.name

  type     = "Vpn"
  vpn_type = var.vpn_type

  active_active = false
  enable_bgp    = false
  sku           = var.vpn_sku

  ip_configuration {
    name                          = "gatewayIPconfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gatewaysubnet.id
  }

  tags = merge(
    local.tags,
    {
      "resource" = "virtual network gateway"
    },
  )
}

resource "azurerm_local_network_gateway" "onprem_gateway" {
  name                = "${local.deprecated_prefix2}-onprem-gw"
  location            = azurerm_resource_group.deprecated_rg.location
  resource_group_name = azurerm_resource_group.deprecated_rg.name
  gateway_address     = var.onprem_s2s_ip
  address_space       = var.onprem_local_addresses

  tags = merge(
    local.tags,
    {
      "resource" = "local network gateway"
    },
  )
}

resource "azurerm_local_network_gateway" "cerner_gateway" {
  name                = "${local.deprecated_prefix2}-cerner-gw"
  location            = azurerm_resource_group.deprecated_rg.location
  resource_group_name = azurerm_resource_group.deprecated_rg.name
  gateway_address     = var.cerner_s2s_ip
  address_space       = var.cerner_local_addresses

  tags = merge(
    local.tags,
    {
      "resource" = "local network gateway"
    },
  )
}

resource "azurerm_virtual_network_gateway_connection" "onpremise" {
  name                = "${local.deprecated_prefix2}-s2s-onprem"
  location            = azurerm_resource_group.deprecated_rg.location
  resource_group_name = azurerm_resource_group.deprecated_rg.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.onprem_gateway.id

  ipsec_policy {
    dh_group         = "DHGroup2"
    ike_encryption   = "AES256"
    ike_integrity    = "SHA256"
    ipsec_encryption = "AES256"
    ipsec_integrity  = "SHA256"
    pfs_group        = "None"
    sa_datasize      = 102400000
    sa_lifetime      = 14400
  }

  routing_weight = 20
  shared_key     = var.vpn_shared_key

  tags = merge(
    local.tags,
    {
      "resource" = "virtual network gateway connection"
    },
  )
}

resource "azurerm_virtual_network_gateway_connection" "cerner" {
  name                = "${local.deprecated_prefix2}-s2s-cerner"
  location            = azurerm_resource_group.deprecated_rg.location
  resource_group_name = azurerm_resource_group.deprecated_rg.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.cerner_gateway.id

  ipsec_policy {
    dh_group         = "DHGroup14"
    ike_encryption   = "AES256"
    ike_integrity    = "SHA256"
    ipsec_encryption = "AES256"
    ipsec_integrity  = "SHA256"
    pfs_group        = "None"
    sa_datasize      = 102400000
    sa_lifetime      = 28800
  }

  routing_weight = 10
  shared_key     = var.cerner_vpn_shared_key

  tags = merge(
    local.tags,
    {
      "resource" = "virtual network gateway connection"
    },
  )
}

resource "azurerm_subnet" "nonprod_fw_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.fw_rg.name
  virtual_network_name = azurerm_virtual_network.nonprod_fw_vnet.name
  address_prefixes     = ["10.105.68.0/24"]
}

resource "azurerm_virtual_network_peering" "nonprod_to_fw" {
  name                         = "nonprod-to-fw"
  resource_group_name          = azurerm_resource_group.deprecated_rg.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.nonprod_fw_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "fw_to_nonprod" {
  name                         = "fw-to-nonprod"
  resource_group_name          = azurerm_resource_group.fw_rg.name
  virtual_network_name         = azurerm_virtual_network.nonprod_fw_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "nonprod_to_mx_shared" {
  name                         = "shared-to-bthhhterraformprod"
  resource_group_name          = azurerm_resource_group.deprecated_rg.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = "/subscriptions/414c73a5-4146-477f-a813-8a1e20dabc33/resourceGroups/CUSSHRSGSH01/providers/Microsoft.Network/virtualNetworks/CUSSHVNT01"
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_route_table" "fw_rt" {
  name                          = "fw-rt"
  location                      = azurerm_resource_group.fw_rg.location
  resource_group_name           = azurerm_resource_group.fw_rg.name
  disable_bgp_route_propagation = false

  route {
    name                   = "route-to-fw"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.nonprod_fw.ip_configuration[0].private_ip_address
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

resource "azurerm_subnet_route_table_association" "nonprod_subnets_to_rt_associations" {
  for_each = local.subnets

  subnet_id      = each.value
  route_table_id = azurerm_route_table.fw_rt.id
}

resource "azurerm_firewall_nat_rule_collection" "this" {
  name                = "global-rules"
  azure_firewall_name = azurerm_firewall.nonprod_fw.name
  resource_group_name = azurerm_resource_group.fw_rg.name
  priority            = 1000
  action              = "Dnat"

  rule {
    name                  = "Application Gateway - Https"
    source_addresses      = ["*"]
    destination_ports     = ["443"]
    translated_port       = "443"
    translated_address    = module.agw.private_ip
    destination_addresses = [azurerm_public_ip.fw_pip_1.ip_address]
    protocols             = ["TCP"]
  }
}

resource "azurerm_virtual_network_peering" "hub_to_pipelines_agent" {
  name                         = "hub-to-pipelines-agent"
  resource_group_name          = azurerm_resource_group.fw_rg.name
  virtual_network_name         = azurerm_virtual_network.nonprod_fw_vnet.name
  remote_virtual_network_id    = join("/", slice(split("/", local.pipelines_agent_subnet_resource.id), 0, 9))
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_virtual_network_peering" "pipelines_agent_to_hub" {
  name                         = "pipelines-agent-to-hub"
  resource_group_name          = local.pipelines_agent_subnet_resource.resource_group_name
  virtual_network_name         = local.pipelines_agent_subnet_resource.virtual_network_name
  remote_virtual_network_id    = azurerm_virtual_network.nonprod_fw_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  use_remote_gateways          = false
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
    next_hop_in_ip_address = azurerm_firewall.nonprod_fw.ip_configuration[0].private_ip_address
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

resource "azurerm_local_network_gateway" "bloomington_gateway" {
  name                = "nonprod-to-blmg"
  location            = azurerm_resource_group.deprecated_rg.location
  resource_group_name = azurerm_resource_group.deprecated_rg.name
  gateway_address     = var.bloomington_ip
  address_space       = var.bloomington_local_addresses

  tags = merge(
    local.tags,
    {
      "resource" = "local network gateway"
    },
  )
}

resource "azurerm_local_network_gateway" "coral_gateway" {
  name                = "nonprod-to-coral"
  location            = azurerm_resource_group.deprecated_rg.location
  resource_group_name = azurerm_resource_group.deprecated_rg.name
  gateway_address     = var.coral_ip
  address_space       = var.coral_local_addresses

  tags = merge(
    local.tags,
    {
      "resource" = "local network gateway"
    },
  )
}

resource "azurerm_virtual_network_gateway_connection" "bloomington" {
  name                = "${local.deprecated_prefix2}-to-bloomington"
  location            = azurerm_resource_group.deprecated_rg.location
  resource_group_name = azurerm_resource_group.deprecated_rg.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.bloomington_gateway.id

  ipsec_policy {
    dh_group         = "DHGroup2"
    ike_encryption   = "AES256"
    ike_integrity    = "SHA256"
    ipsec_encryption = "AES256"
    ipsec_integrity  = "SHA256"
    pfs_group        = "None"
    sa_datasize      = 102400000
    sa_lifetime      = 14400
  }

  routing_weight = 10
  shared_key     = var.bloomington_vpn_shared_key

  tags = merge(
    local.tags,
    {
      "resource" = "virtual network gateway connection"
    },
  )
}

resource "azurerm_virtual_network_gateway_connection" "coral" {
  name                = "${local.deprecated_prefix2}-to-coral"
  location            = azurerm_resource_group.deprecated_rg.location
  resource_group_name = azurerm_resource_group.deprecated_rg.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.coral_gateway.id


    shared_key     = var.coral_vpn_shared_key

  tags = merge(
    local.tags,
    {
      "resource" = "virtual network gateway connection"
    },
  )
}