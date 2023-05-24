resource "azurerm_traffic_manager_profile" "this" {
  for_each = var.profiles

  name                   = format("%s%s", var.prefix, each.key)
  resource_group_name    = var.resource_group_name
  traffic_routing_method = var.routing_method

  dns_config {
    # Special words such a 'login' are not allowed at Azure as part of a public names. More: https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-manager-reserved-resource-name
    # Workaround to replace 'login' with 'logon'
    relative_name = format("%s%s", var.prefix, replace(each.key, "login", "logon"))

    ttl = 100
  }

  monitor_config {
    protocol = "HTTPS"
    port     = 443
    path     = "/"
  }

  tags = merge(
    var.tags,
    {
      "resource" = "traffic manager profile"
    },
  )
}

resource "azurerm_traffic_manager_external_endpoint" "this" {
  for_each = var.profiles

  name       = "${each.key}-onprem"
  profile_id = azurerm_traffic_manager_profile.this[each.key].id
  target     = each.value
  enabled    = var.enable_onprem_endpoints
  weight     = 100
}

resource "azurerm_traffic_manager_azure_endpoint" "this" {
  for_each = var.target_resource_id != null ? var.profiles : {}

  name               = "${each.key}-cloud"
  profile_id         = azurerm_traffic_manager_profile.this[each.key].id
  target_resource_id = var.target_resource_id
  enabled            = var.enable_azure_endpoints
  weight             = 10
}
