variable "application" {
  description = "Application name."
  default     = "AFO"
  type        = string
}

variable "application_prefix" {
  description = "Application prefix."
  default     = "afo"
  type        = string
}

variable "db_backups_environments" {
  description = "Map of environments which require storage account to store database backups."
  default = {
    dev-backups    = ["dev-backups/FULL", "dev-backups/ora_expdp"]
    hotfix-backups = ["hotfix-backups/FULL", "hotfix-backups/ora_expdp"]
    stage-backups  = ["stage-backups/FULL", "stage-backups/ora_expdp"]
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
