resource "azurerm_public_ip" "bastion" {
  name                = "${local.deprecated_prefix2}-pip"
  location            = azurerm_resource_group.deprecated_rg.location
  resource_group_name = azurerm_resource_group.deprecated_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [1, 2, 3]

  tags = merge(
    local.tags,
    {
      "resource" = "public ip"
    },
  )
}

resource "azurerm_bastion_host" "this" {
  name                = "${local.deprecated_prefix2}-bastion"
  location            = azurerm_resource_group.deprecated_rg.location
  resource_group_name = azurerm_resource_group.deprecated_rg.name

  ip_configuration {
    name                 = azurerm_public_ip.bastion.name
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  tags = merge(
    local.tags,
    {
      "resource" = "bastion host"
    },
  )
}
