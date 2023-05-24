variable "application" {
  description = "Application name."
  default     = "Private Duty"
  type        = string
}

variable "application_prefix" {
  description = "Application prefix."
  default     = "pd"
  type        = string
}

variable "db_backups_environments" {
  description = "Map of environments which require storage account to store database backups."
  default = {
    qa-backups = ["qa-backups/FULL"]
  }
  type = map(list(string))
}

variable "environment" {
  description = "Environment name."
  default     = "Shared"
  type        = string
}

variable "environment_prefix" {
  description = "Environment prefix to use."
  default     = "sh"
  type        = string
}

variable "location" {
  description = "Azure region."
  default     = "East US 2"
  type        = string
}

variable "tags" {
  description = "Tags to organize Azure resources."
  type        = map(string)
  default = {
    terraform = "true"
  }
}
