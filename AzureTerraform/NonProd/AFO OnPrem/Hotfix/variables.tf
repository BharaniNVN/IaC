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
  default     = "Hotfix"
}

variable "environment_prefix" {
  description = "Environment prefix to use."
  default     = "t4"
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
