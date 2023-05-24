resource "azurerm_bastion_host" "this" {
  name                = "${local.deprecated_prefix}-vnet-bastion"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name

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
