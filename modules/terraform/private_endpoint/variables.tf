variable "resource_group_resource" {
  description = "Partial resource group resource with keys for its name and location."
  default     = { name = "", location = "" }
  type        = object({ name = string, location = string })
}

variable "location" {
  description = "Azure region where resources will be deployed."
  default     = ""
}

variable "resource" {
  description = "Partial resource of the Private Link Enabled resource with two keys for its ID and name."
  default     = null
  type        = object({ id = string, name = string })
}

variable "subnet_resource" {
  description = "Partial Subnet resource with two keys for ID of the subnet and its address prefix."
  default     = null
  type        = object({ id = string, address_prefixes = list(string) })
}

variable "endpoint" {
  description = "Name of the subresource which the Private Endpoint is able to connect to."
  default     = null
  type        = string
}

variable "ip_index" {
  description = "Index of ip address in subnet to be used by private endpoint."
  default     = 0
}

variable "temporary_nic_prefix" {
  description = "Prefix of temporary network interface in which ip addresses will be reserved."
  default     = "remove-me-"
}

variable "tags" {
  description = "Tags to organize Azure resources."
  default     = {}
  type        = map(string)
}

variable "module_depends_on" {
  description = "Names of resources this module should depend upon."
  default     = null
  type        = any
}
