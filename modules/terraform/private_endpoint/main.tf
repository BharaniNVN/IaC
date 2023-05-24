locals {
  location            = coalesce(var.location, var.resource_group_resource["location"])
  prefix              = format("%s-%s", var.resource.name, var.endpoint)
  resource_group_name = var.resource_group_resource["name"]
}

data "external" "reserve_ips" {
  program = ["pwsh", "-file", "${path.module}/script.ps1"]

  query = {
    "index"         = var.ip_index
    "prefix"        = var.temporary_nic_prefix
    "rg"            = local.resource_group_name
    "subnet_id"     = var.subnet_resource.id
    "address_space" = var.subnet_resource.address_prefixes[0]
    "name"          = "${local.prefix}-pe"
  }

  depends_on = [var.module_depends_on]
}

resource "azurerm_private_endpoint" "this" {
  name                = "${local.prefix}-pe"
  location            = local.location
  resource_group_name = local.resource_group_name
  subnet_id           = var.subnet_resource.id

  private_service_connection {
    name                           = "${local.prefix}-psc"
    private_connection_resource_id = var.resource.id
    subresource_names              = [var.endpoint]
    is_manual_connection           = false
  }

  tags = merge(
    var.tags,
    {
      "resource" = "private endpoint"
    },
  )

  depends_on = [data.external.reserve_ips]
}

data "external" "clean_reserved_ips" {
  program = ["pwsh", "-command", "& {$vars=ConvertFrom-Json $([Console]::In.ReadLine()); if ($vars.id.Length -gt 0) {$result = az network nic delete --ids $vars.id --only-show-errors 2>&1}; if ($LASTEXITCODE) {throw $result} elseif ($error.Count) { exit 1 } else { return '{}' } }"]

  query = {
    "id" = lookup(data.external.reserve_ips.result, "id", "")
  }

  depends_on = [azurerm_private_endpoint.this]
}
