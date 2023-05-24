resource "azurerm_resource_group" "fw_rg" {
  name     = "${var.prefix}-rg"
  location = var.location

  tags = merge(
    local.tags,
    {
      "resource" = "resource group"
    },
  )
}

resource "azurerm_public_ip" "azure_firewall_prod_1" {
  name                = "${var.prefix}-fw1-pip"
  location            = azurerm_resource_group.fw_rg.location
  resource_group_name = azurerm_resource_group.fw_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s%s-fw1-pip", var.prefix, var.public_ip_domain_suffix)

  tags = merge(
    local.tags,
    {
      "resource" = "public ip"
    },
  )
}

resource "azurerm_public_ip" "azure_firewall_prod_2" {
  name                = "${var.prefix}-fw2-pip"
  location            = azurerm_resource_group.fw_rg.location
  resource_group_name = azurerm_resource_group.fw_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s%s-fw2-pip", var.prefix, var.public_ip_domain_suffix)

  tags = merge(
    local.tags,
    {
      "resource" = "public ip"
    },
  )
}

resource "azurerm_public_ip" "azure_firewall_prod_3" {
  name                = "${var.prefix}-fw3-pip"
  location            = azurerm_resource_group.fw_rg.location
  resource_group_name = azurerm_resource_group.fw_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s%s-fw3-pip", var.prefix, var.public_ip_domain_suffix)

  tags = merge(
    local.tags,
    {
      "resource" = "public ip"
    },
  )
}

resource "azurerm_public_ip" "azure_firewall_prod_4" {
  name                = "${var.prefix}-fw4-pip"
  location            = azurerm_resource_group.fw_rg.location
  resource_group_name = azurerm_resource_group.fw_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s%s-fw4-pip", var.prefix, var.public_ip_domain_suffix)

  tags = merge(
    local.tags,
    {
      "resource" = "public ip"
    },
  )
}

resource "azurerm_public_ip" "azure_firewall_dr_1" {
  name                = "${var.prefix}-dr1-pip"
  location            = azurerm_resource_group.fw_rg.location
  resource_group_name = azurerm_resource_group.fw_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = format("%s%s-dr1-pip", var.prefix, var.public_ip_domain_suffix)

  tags = merge(
    local.tags,
    {
      "resource" = "public ip"
    },
  )
}

resource "azurerm_firewall" "hub_fw" {
  name                = "${var.prefix}-fw"
  location            = azurerm_resource_group.fw_rg.location
  resource_group_name = azurerm_resource_group.fw_rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = azurerm_public_ip.azure_firewall_prod_1.name
    public_ip_address_id = azurerm_public_ip.azure_firewall_prod_1.id
    subnet_id            = azurerm_subnet.azure_firewall_subnet.id
  }

  ip_configuration {
    name                 = azurerm_public_ip.azure_firewall_prod_2.name
    public_ip_address_id = azurerm_public_ip.azure_firewall_prod_2.id
  }

  ip_configuration {
    name                 = azurerm_public_ip.azure_firewall_prod_3.name
    public_ip_address_id = azurerm_public_ip.azure_firewall_prod_3.id
  }

  ip_configuration {
    name                 = azurerm_public_ip.azure_firewall_prod_4.name
    public_ip_address_id = azurerm_public_ip.azure_firewall_prod_4.id
  }

  ip_configuration {
    name                 = azurerm_public_ip.azure_firewall_dr_1.name
    public_ip_address_id = azurerm_public_ip.azure_firewall_dr_1.id
  }

  tags = merge(
    local.tags,
    {
      "resource" = "azure firewall"
    },
  )
}

resource "azurerm_firewall_network_rule_collection" "this" {
  name                = "global-rules"
  azure_firewall_name = azurerm_firewall.hub_fw.name
  resource_group_name = azurerm_resource_group.fw_rg.name
  priority            = 1000
  action              = "Allow"

  rule {
    name                  = "Azure KMS for Windows activation"
    source_addresses      = ["10.0.0.0/8"]
    destination_ports     = ["1688"]
    destination_addresses = ["*"]
    protocols             = ["TCP"]
  }

  rule {
    name                  = "DNS names resolution"
    source_addresses      = ["10.0.0.0/8"]
    destination_ports     = ["53"]
    destination_addresses = ["*"]
    protocols             = ["UDP", "TCP"]
  }
}

resource "azurerm_firewall_network_rule_collection" "to_vnet_cusupvnt01" {
  name                = "to_vnet_cusupvnt01"
  azure_firewall_name = azurerm_firewall.hub_fw.name
  resource_group_name = azurerm_resource_group.fw_rg.name
  priority            = 1050
  action              = "Allow"

  rule {
    name                  = "inbound"
    source_addresses      = ["10.221.0.12", "10.221.2.110", "10.221.2.115"]
    destination_ports     = ["*"]
    destination_addresses = ["10.105.0.0/18"]
    protocols             = ["Any"]
  }

  rule {
    name                  = "outbound"
    source_addresses      = ["10.105.0.0/18"]
    destination_ports     = ["*"]
    destination_addresses = ["10.221.0.12", "10.221.2.110", "10.221.2.115"]
    protocols             = ["Any"]
  }
}

resource "azurerm_firewall_application_rule_collection" "this" {
  name                = "global-rules"
  azure_firewall_name = azurerm_firewall.hub_fw.name
  resource_group_name = azurerm_resource_group.fw_rg.name
  priority            = 1000
  action              = "Allow"

  rule {
    name             = "Internet http(s) access"
    source_addresses = ["10.0.0.0/8"]
    target_fqdns     = ["*"]

    protocol {
      port = "80"
      type = "Http"
    }

    protocol {
      port = "8080"
      type = "Http"
    }

    protocol {
      port = "443"
      type = "Https"
    }
  }
}

resource "azurerm_firewall_network_rule_collection" "pipelines_agent" {
  name                = "pipelines-agent"
  azure_firewall_name = azurerm_firewall.hub_fw.name
  resource_group_name = azurerm_resource_group.fw_rg.name
  priority            = 1020
  action              = "Allow"

  rule {
    name                  = "outbound"
    source_addresses      = local.pipelines_agent_subnet_resource.address_prefixes
    destination_ports     = ["*"]
    destination_addresses = ["*"]
    protocols             = ["Any"]
  }
}

resource "azurerm_monitor_diagnostic_setting" "fw_diag_log_export" {
  name                           = "${var.prefix}-fw-diag-log-export"
  target_resource_id             = azurerm_firewall.hub_fw.id
  storage_account_id             = azurerm_storage_account.fw_storage_accout.id
  log_analytics_destination_type = "AzureDiagnostics"
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.hub_la.id

  dynamic "log" {
    for_each = {
      "AzureFirewallDnsProxy"        = false,
      "AzureFirewallApplicationRule" = true,
      "AzureFirewallNetworkRule"     = true,
    }

    content {
      category = log.key
      enabled  = log.value

      retention_policy {
        enabled = log.value
        days    = log.value ? 365 : 0
      }
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = false

    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_storage_account" "fw_storage_accout" {
  name                            = "${var.prefix}fwlogsstore"
  resource_group_name             = azurerm_resource_group.fw_rg.name
  location                        = azurerm_resource_group.fw_rg.location
  account_kind                    = "Storage"
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
  enable_https_traffic_only       = true
  min_tls_version                 = "TLS1_2"

  tags = merge(
    local.tags,
    {
      "resource" = "storage account"
    },
  )
}
