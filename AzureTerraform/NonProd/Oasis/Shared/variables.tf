variable "application" {
  description = "Application name."
  default     = "Oasis Coding Station"
}

# variable "application_prefix" {
#   description = "Application prefix."
#   default     = "ocs"
# }

variable "environment" {
  description = "Environment name."
  default     = "Shared"
}

# variable "environment_prefix" {
#   description = "Environment prefix to use."
#   default     = "sh"
# }

variable "deprecated_environment_prefix" {
  description = "Environment prefix to use."
  default     = "nonprod"
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
