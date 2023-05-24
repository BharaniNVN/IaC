variable "application" {
  description = "Application name."
  default     = "orchestration"
}

variable "application_prefix" {
  description = "Application prefix."
  default     = "ado"
}

variable "environment" {
  description = "Environment name."
  default     = "Hotfix"
}

variable "environment_prefix" {
  description = "Environment prefix to use."
  default     = "hfx"
}

variable "location" {
  description = "Azure region."
  default     = "East US 2"
}

variable "tags" {
  description = "Tags to organize Azure resources."
  type        = map(string)
  default = {
    terraform = "true"
  }
}

variable "sql_admin_user" {
  description = "Username for admin account at Azure SQL server"
  default     = "EHCNC\\build"
}

variable "sql_admin_pswd" {
  description = "Password for admin account at Azure SQL server"
  default     = ""
}

variable "sql_database" {
  description = "SQL Database"
  default     = "EnvironmentLookup"
}


variable "sql_server_name" {
  description = "SQL server ip address "
  default     = "10.4.1.74"
}

variable "sql_server_port" {
  description = "Sql server port"
  default     = 1593
}

variable "solution_name" {
  description = "Name(s) of the solutions for Log Analytics workspace."
  default     = ["ApplicationInsights", "AzureWebAppsAnalytics"]
}