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
  default     = "Shared"
}

variable "environment_prefix" {
  description = "Environment prefix to use."
  default     = "sh"
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