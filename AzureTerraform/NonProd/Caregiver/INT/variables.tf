variable "application" {
  description = "Application name."
  default     = "Caregiver Retention"
  type        = string
}

variable "application_prefix" {
  description = "Application prefix."
  default     = "crml"
  type        = string
}

variable "environment" {
  description = "Environment name."
  default     = "Int"
  type        = string
}

variable "environment_prefix" {
  description = "Environment prefix to use."
  default     = "int"
  type        = string
}

# variable "failover_location" {
#   description = "Azure region."
#   default     = "East US"
#   type        = string
# }

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
