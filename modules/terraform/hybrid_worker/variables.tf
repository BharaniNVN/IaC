variable "worker_group_name" {
  description = "Name of the Hybrid Worker Group to which VM will be joined. Will be the the same as the VM name if not specified"
  default     = null
  type        = string
}

variable "automation_account_name" {
  description = "Name of the parent automation account"
  type        = string
}

variable "automation_account_rg_name" {
  description = "Name of the resource group containing automation account"
  type        = string
}

variable "automation_account_endpoint" {
  description = "Endpoint URL of the parent automation account"
  type        = string
}

variable "type_handler_version" {
  description = "Version of AzureRM extension version for Hybrid Worker"
  type        = string
  default     = "0.1"
}

variable "virtual_machine_resource" {
  description = "List of partial VM resources that will be joined to Hybrid Worker Group"
  type        = map(string)
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
