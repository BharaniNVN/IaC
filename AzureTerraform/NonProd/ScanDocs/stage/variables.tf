variable "application" {
  description = "Application name."
  default     = "ScanDocs"
}

variable "application_prefix" {
  description = "Application prefix."
  default     = "ScanDocs"
}

variable "environment" {
  description = "Environment name."
  default     = "Stage"
}

# variable "environment_prefix" {
#   description = "Environment prefix to use."
#   default     = "stg"
# }

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
