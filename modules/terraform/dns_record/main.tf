locals {
  # cloudflare_records = [for i in setproduct(local.names, local.type == "CNAME" ? [var.targets[0]] : var.targets) : format("%s%s%s", i[0], local.separator, i[1])]
  names              = [for n in var.names : lower(n)]
  separator          = "___"
  type               = upper(var.type)
  azurerm_tags = merge(
    var.azurerm_tags,
    {
      "resource" = "dns record"
    },
  )
}

# resource "cloudflare_record" "this" {
#   for_each = var.cloudflare_zone_id == null ? [] : toset(local.cloudflare_records)

#   zone_id  = var.cloudflare_zone_id
#   name     = split(local.separator, each.value)[0]
#   type     = local.type
#   value    = split(local.separator, each.value)[1]
#   ttl      = var.ttl
#   priority = length(var.mx_priority) == length(var.targets) ? var.mx_priority[index(var.targets, split(local.separator, each.value)[1])] : var.mx_priority[0]
# }

resource "azurerm_dns_a_record" "this" {
  for_each = local.type == "A" ? toset(local.names) : []

  name                = each.value
  zone_name           = var.azurerm_dns_zone_name
  resource_group_name = var.azurerm_resource_group_name
  ttl                 = var.ttl
  records             = var.targets

  tags = local.azurerm_tags
}

resource "azurerm_dns_cname_record" "this" {
  for_each = local.type == "CNAME" ? toset(local.names) : []

  name                = each.value
  zone_name           = var.azurerm_dns_zone_name
  resource_group_name = var.azurerm_resource_group_name
  ttl                 = var.ttl
  record              = var.targets[0]

  tags = local.azurerm_tags
}

resource "azurerm_dns_mx_record" "this" {
  for_each = local.type == "MX" ? toset(local.names) : []

  name                = each.value
  zone_name           = var.azurerm_dns_zone_name
  resource_group_name = var.azurerm_resource_group_name
  ttl                 = var.ttl

  dynamic "record" {
    for_each = var.targets

    content {
      preference = length(var.mx_priority) == length(var.targets) ? var.mx_priority[index(var.targets, record.value)] : var.mx_priority[0]
      exchange   = record.value
    }
  }

  tags = local.azurerm_tags
}

resource "azurerm_dns_txt_record" "this" {
  for_each = local.type == "TXT" ? toset(local.names) : []

  name                = each.value
  zone_name           = var.azurerm_dns_zone_name
  resource_group_name = var.azurerm_resource_group_name
  ttl                 = var.ttl

  dynamic "record" {
    for_each = var.targets

    content {
      value = record.value
    }
  }

  tags = local.azurerm_tags
}

resource "azurerm_dns_ns_record" "this" {
  for_each = local.type == "NS" ? toset(local.names) : []

  name                = each.value
  zone_name           = var.azurerm_dns_zone_name
  resource_group_name = var.azurerm_resource_group_name
  ttl                 = var.ttl
  records             = var.targets

  tags = local.azurerm_tags
}
