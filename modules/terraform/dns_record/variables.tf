# variable "cloudflare_zone_id" {
#   description = "ID of the DNS zone in the Cloudflare."
#   default     = null
#   type        = string
# }

variable "azurerm_resource_group_name" {
  description = "Name of the resource group which contains DNS zone."
  type        = string
}

variable "azurerm_dns_zone_name" {
  description = "Name of the DNS zone."
  type        = string
}

variable "names" {
  description = "List of the resource record names to create."
  default     = []
  type        = list(string)
}

variable "targets" {
  description = "List of target values for DNS record. Only one target should be specified for CNAME record type."
  default     = []
  type        = list(string)
}

variable "type" {
  description = "Type of the DNS record."
  default     = "A"
  type        = string
}

variable "ttl" {
  description = "Record lifetime after which DNS resolvers must discard or refresh the value."
  default     = 3600
  type        = number
}

variable "mx_priority" {
  description = "List of priority values specified accordingly for 'targets' variable."
  default     = [0]
  type        = list(number)
}

variable "azurerm_tags" {
  description = "Tags to organize Azure resources."
  default     = {}
  type        = map(string)
}
