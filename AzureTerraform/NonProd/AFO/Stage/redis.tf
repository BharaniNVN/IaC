resource "azurerm_redis_cache" "redis" {
  name                          = "${local.prefix}-redis"
  location                      = azurerm_resource_group.this.location
  resource_group_name           = azurerm_resource_group.this.name
  capacity                      = 0
  family                        = "C"
  sku_name                      = "Basic"
  minimum_tls_version           = "1.2"
  public_network_access_enabled = "false"

  tags = merge(
    local.tags,
    {
      "resource" = "redis cache"
    },
  )
}

module "redis" {
  source = "../../../../modules/terraform/private_endpoint"

  resource_group_resource = azurerm_resource_group.this
  subnet_resource         = azurerm_subnet.dmz
  resource                = azurerm_redis_cache.redis
  endpoint                = "redisCache"
  ip_index                = 22
  tags                    = local.tags
  module_depends_on       = [module.file]
}
