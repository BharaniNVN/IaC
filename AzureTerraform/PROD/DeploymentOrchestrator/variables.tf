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
  default     = "Prod"
}

variable "environment_prefix" {
  description = "Environment prefix to use."
  default     = "p"
}

variable "location" {
  description = "Azure region."
  default     = "North Central US"
}

variable "tags" {
  description = "Tags to organize Azure resources."
  type        = map(string)
  default = {
    terraform = "true"
  }
}

variable "sql_user" {
  description = "Username for admin account at Azure SQL server"
  default     = "CAWPROD\\sqlflagagent"
}

variable "sql_pswd" {
  description = "Password for admin account at Azure SQL server"
  default     = ""
}

variable "sql_database" {
  description = "SQL database"
  default     = "EnvironmentLookup"
}


variable "sql_server_name" {
  description = "Sql server dns name or ip address"
  default     = "192.168.10.15"
}

variable "sql_server_port" {
  description = "Sql server port"
  default     = 1433
}

variable "solution_name" {
  description = "Name(s) of the solutions for Log Analytics workspace."
  default     = ["ApplicationInsights", "AzureWebAppsAnalytics"]
}