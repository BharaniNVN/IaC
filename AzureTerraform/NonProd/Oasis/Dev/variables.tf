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

variable "azure_sql_version" {
  description = "The version for the new server. Valid values are: 2.0 (for v11 server) and 12.0 (for v12 server)"
  default     = "12.0"
  type        = string
}

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

variable "dotnet_framework_version" {
  description = ".NET Framework version used at app service. Possible values are 'v2.0' (= .net 3.5) or 'v4.0' (= latest stable .net 4.x.x)"
  default     = "v4.0"
  type        = string
}

variable "environment" {
  description = "Environment name."
  default     = "Dev"
  type        = string
}

variable "environment_prefix" {
  description = "Environment prefix to use."
  default     = "dev"
  type        = string
}

variable "location" {
  description = "Azure region."
  default     = "East US 2"
  type        = string
}

variable "remote_debugging_version" {
  description = "Version of Visual Studio should the Remote Debugger be compatible with. Possible values are VS2012, VS2013, VS2015 and VS2017"
  default     = "VS2017"
  type        = string
}

variable "secondary_location" {
  description = "Azure region for Application Insights."
  default     = "East US"
  type        = string
}

variable "solution_name" {
  description = "Name(s) of the solutions for Log Analytics workspace."
  default     = ["ApplicationInsights", "AntiMalware", "SecurityCenterFree", "AzureWebAppsAnalytics", "SQLAssessment", "AzureSQLAnalytics"]
  type        = list(string)
}

variable "tags" {
  description = "Tags to organize Azure resources."
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
