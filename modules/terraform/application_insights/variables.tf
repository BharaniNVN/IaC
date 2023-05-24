variable "api_keys" {
  description = "Map of the Application Insights API keys names and list of permissions. Allowed values for permissions are - 'authenticate_sdk_control_channel', 'full_permissions', 'read_telemetry' and 'write_annotations'. If API key is only one - its value could fetched from output 'api_key' directly in addition to 'api_keys' map."
  default     = {}
  type        = map(list(string))
}

variable "application_type" {
  description = "Specifies the type of Application Insights to create."
  default     = "web"
  type        = string
}

variable "daily_data_cap_in_gb" {
  description = "Specifies the Application Insights component daily data volume cap in GB."
  default     = null
  type        = number
}

variable "daily_data_cap_notifications_disabled" {
  description = "Specifies if a notification email will be send when the daily data volume cap is met."
  default     = false
  type        = bool
}

variable "disable_ip_masking" {
  description = "By default the real client ip is masked as 0.0.0.0 in the logs. Use this argument to disable masking and log the real client ip."
  default     = false
  type        = bool
}

variable "location" {
  description = "Azure region where resources will be deployed. Takes precedence over resource_group_resource['location'] value in case both are specified."
  default     = null
  type        = string
}

variable "log_analytics_workspace_resource" {
  description = "Log Analytics resource with ID property. If set workspace-based Application Insights will be created otherwise - a classic one."
  default     = null
  type        = object({ id = string })
}

variable "name" {
  description = "Specifies the name of the Application Insights component."
  type        = string
}

variable "resource_group_resource" {
  description = "Partial existing resource group resource with keys for its name and location."
  type        = object({ name = string, location = string })
}

variable "retention_in_days" {
  description = "Specifies the retention period in days."
  default     = 90
  type        = number
}

variable "sampling_percentage" {
  description = "Specifies the percentage of the data produced by the monitored application that is sampled for Application Insights telemetry."
  default     = 100
  type        = number
}

variable "tags" {
  description = "A mapping of tags which should be assigned to the resources."
  default     = {}
  type        = map(string)
}

variable "web_tests" {
  description = "Map of the web tests names and their configuration values."
  default     = {}
  type        = any
}
