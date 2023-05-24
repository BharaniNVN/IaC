variable "application" {
  description = "Application name."
  default     = "AFO OnPrem"
}

variable "application_prefix" {
  description = "Application prefix."
  default     = "afo"
}

variable "environment" {
  description = "Environment name."
  default     = "Dev"
}

variable "environment_prefix" {
  description = "Environment prefix to use."
  default     = "t6"
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
