variable "application" {
  description = "Application name."
  default     = ""
  type        = string
}

variable "application_prefix" {
  description = "Application prefix."
  default     = ""
  type        = string
}

variable "environment" {
  description = "Environment name."
  default     = "test"
  type        = string
}

variable "environment_prefix" {
  description = "Environment prefix to use."
  default     = "test"
  type        = string
}

variable "resource_group_resource" {
  description = "Partial existing resource group resource with keys for its name and location."
  default     = { name = "", location = "" }
  type        = object({ name = string, location = string })
}

variable "resource_group_name" {
  description = "Resource group name. Takes precedence over resource_group_resource['name'] value in case both are specified and name or location is not equal."
  default     = ""
  type        = string
}

variable "location" {
  description = "Azure region where resources will be deployed. Takes precedence over resource_group_resource['location'] value in case both are specified."
  default     = ""
  type        = string
}

variable "run_as_account_username" {
  description = "Application ID of the service principal which has permissions for Start/Stop VMs. If not specified ID of the running principal will be used."
  default     = ""
  type        = string
}

variable "run_as_account_password" {
  description = "Client secret for the service principal."
  default     = ""
  type        = string
}

variable "sql_sa_password" {
  description = "SQL SA password used by runbooks for automatic DB restores."
  default     = ""
  type        = string
}

variable "local_admin_user" {
  description = "Local VM administrative account."
  default     = "BtHHHAzureAdmin"
  type        = string
}

variable "local_admin_pswd" {
  description = "Password for local VM administrative account."
  default     = ""
  type        = string
}

variable "tag_stage1" {
  description = "Name of the tag which will be used to include VMs into processing by scripts in Stage 1 (these VMs will be processed in the first place)."
  default     = "backend"
  type        = string
}

variable "tag_stage1_value" {
  description = "Value of the tag which will be used to include VMs into processing by scripts in Stage 1 (these VMs will be processed in the first place)."
  default     = "true"
  type        = string
}

variable "tag_stage2" {
  default     = "application"
  description = "Name of the tag which will be used to include VMs into processing by scripts in Stage 2 (these VMs will be processed after Stage 1)."
  type        = string
}

variable "tag_stage2_value" {
  description = "Value of the tag which will be used to include VMs into processing by scripts in Stage 2 (these VMs will be processed after Stage 1)."
  default     = "test"
  type        = string
}

variable "tag_to_exclude" {
  default     = "doNotShutdown"
  description = "Name of the tag which will be used to exclude VMs from processing by scripts."
  type        = string
}

variable "tag_to_exclude_value" {
  default     = "true"
  description = "Value of the tag which will be used to exclude VMs from processing by scripts."
  type        = string
}

variable "modules_base_url" {
  description = "Link to base repository of Powershell modules"
  default     = "https://www.powershellgallery.com/api/v2/package/"
  type        = string
}

variable "start_week_days" {
  description = "List of days of the week that the job should execute on."
  default     = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
  type        = list(string)
}

variable "stop_week_days" {
  description = "List of days of the week that the job should execute on. In case of date change between 'Start VMs' and 'Stop VMs' time trigger this should be adjusted accordingly."
  default     = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
  type        = list(string)
}

variable "timezone" {
  description = "The timezone of the start and stop time. For possible values see: https://s2.automation.ext.azure.com/api/Orchestrator/TimeZones?_=1594792230258"
  default     = "Etc/UTC"
  type        = string
}

variable "permissions" {
  description = "Additional permissions which should be assigned on an automation account object in form of map where key is defining the role definition name and value - the list of service principals IDs the role should be assigned to."
  default     = {}
  type        = map(list(string))
}

variable "start_time" {
  description = "Time of the day to run start VMs script."
  default     = ""
  type        = string
}

variable "stop_time" {
  description = "Time of the day to run stop VMs script."
  default     = ""
}

variable "log_analytics_workspace_resource" {
  description = "Partial Log Analytics Workspace resource with key for its ID."
  default     = null
  type        = object({ id = string })
}

variable "tags" {
  description = "Tags to organize Azure resources."
  default     = {}
  type        = map(string)
}
