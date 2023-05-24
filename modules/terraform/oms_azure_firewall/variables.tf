variable "location" {
  description = "Azure region where resources will be deployed."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name of the Log Analytics"
  type        = string
}

variable "tags" {
  description = "Tags to organize Azure resources."
  default     = {}
  type        = map(string)
}

variable "workspace_name" {
  description = "Log Analytics workspace name"
  type        = string
}
