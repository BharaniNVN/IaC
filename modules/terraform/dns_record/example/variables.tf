variable "cloudflare_zone_id" {
  default = null
}

variable "azurerm_resource_group_name" {
  default = null
}

variable "azurerm_dns_zone_name" {
  default = null
}

variable "ttl" {
  default = 300
}

variable "tags" {
  default = {
    "environment" = "test"
  }
}
