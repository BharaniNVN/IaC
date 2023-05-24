variable "eventhub_name" {
  description = "Target Event Hub name"
  default     = ""
  type        = string
}

variable "eventhub_policy_id" {
  description = "Shared access policy(Authorization rule) of the Event Hub Namespace"
  default     = ""
  type        = string
}

variable "log_analytics_resource_id" {
  description = "The target resource ID of log analytics"
  default     = ""
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for ARM template deployment"
  type        = string
}

variable "sql_server_name" {
  description = "Name of SQL server"
  type        = string
}

variable "tags" {
  description = "Tags to organize Azure resources."
  default     = {}
  type        = map(string)
}
