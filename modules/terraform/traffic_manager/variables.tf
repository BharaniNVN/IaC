variable "enable_azure_endpoints" {
  description = "Whether to enable cloud endpoint or not."
  default     = false
  type        = bool
}

variable "enable_onprem_endpoints" {
  description = "Whether to enable on-prem endpoint or not."
  default     = true
  type        = bool
}

variable "prefix" {
  description = "Prefix which will be used in the names of Traffic Manager profiles."
  default     = "drbtree"
  type        = string
}

variable "profiles" {
  description = "A map of of externally published resources. Must follow [Profile_name] = [Target FQDN] syntax. IP adresses are NOT allowed."
  default     = {}
  type        = map(string)
}

variable "resource_group_name" {
  description = "Name of the resource group to deploy to."
  type        = string
}

variable "routing_method" {
  description = "Algorithm used to route traffic. Possible values are: Geographic, MultiValue, Performance, Priority, Subnet or Weighted."
  default     = "Weighted"
  type        = string
}

variable "tags" {
  description = "Tags to organize Azure resources."
  default     = {}
  type        = map(string)
}

variable "target_resource_id" {
  description = "Required for all Azure endpoints. Should be .id of Azure resource external traffic to be routed during disaster."
  default     = null
  type        = string
}
