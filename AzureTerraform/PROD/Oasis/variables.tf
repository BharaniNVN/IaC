variable "application" {
  description = "Application name."
  default     = "Oasis Coding Station"
  type        = string
}

# variable "application_prefix" {
#   description = "Application prefix."
#   default     = "ocs"
#   type        = string
# }

variable "azure_sql_admin" {
  description = "The administrator login name for the new server"
  default     = "AzSqlSaAdmin"
  type        = string
}

variable "azure_sql_admin_pswd" {
  description = "The password associated with the administrator user"
  default     = ""
  type        = string
}

variable "azure_sql_version" {
  description = "The version for the new server. Valid values are: 2.0 (for v11 server) and 12.0 (for v12 server)"
  default     = "12.0"
  type        = string
}

variable "deprecated_application_prefix" {
  description = "Deprecated application prefix."
  default     = "oasis"
  type        = string
}

variable "dotnet_framework_version" {
  description = ".NET Framework version used at app service. Possible values are 'v2.0' (= .net 3.5) or 'v4.0' (= latest stable .net 4.x.x)"
  default     = "v4.0"
  type        = string
}

variable "environment" {
  description = "Environment name."
  default     = "Prod"
  type        = string
}

# variable "environment_prefix" {
#   description = "Environment prefix to use."
#   default     = "p"
#   type        = string
# }

variable "failover_location" {
  description = "Azure region CosmosDB is replicated to."
  default     = "South Central US"
  type        = string
}

variable "location" {
  description = "Azure region."
  default     = "North Central US"
  type        = string
}

variable "production_environments" {
  description = "List of Production environments to create Service Bus subscription rules."
  default     = ["P2", "P3", "P4", "P5", "P6", "P7", "P8", "P9", "P10"]
  type        = set(string)
}

variable "remote_debugging_version" {
  description = "Version of Visual Studio should the Remote Debugger be compatible with. Possible values are VS2012, VS2013, VS2015 and VS2017"
  default     = "VS2017"
  type        = string
}

variable "solution_name" {
  description = "Name(s) of the solutions for Log Analytics workspace."
  default     = ["ApplicationInsights", "AntiMalware", "SecurityCenterFree", "AzureWebAppsAnalytics", "SQLAssessment", "AzureSQLAnalytics"]
}

variable "tags" {
  description = "Any tags which should be assigned to the resources in this example"
  type        = map(string)
  default = {
    terraform = "true"
  }
}

variable "website_node_def_ver" {
  description = "Node.js version to use."
  default     = "8.12.0"
  type        = string
}
