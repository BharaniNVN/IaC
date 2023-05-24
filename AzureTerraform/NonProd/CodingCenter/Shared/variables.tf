variable "application" {
  description = "Application name."
  default     = "Revenue Cycle Management"
  type        = string
}

# variable "application_prefix" {
#   description = "Application prefix."
#   default     = "rcm"
#   type        = string
# }

variable "deprecated_application_prefix" {
  description = "Application prefix."
  default     = "CodingCenter"
  type        = string
}

variable "environment" {
  description = "Environment name."
  default     = "Shared"
  type        = string
}

# variable "environment_prefix" {
#   description = "Environment prefix to use."
#   default     = "sh"
#   type        = string
# }

variable "deprecated_environment_prefix" {
  description = "Environment prefix to use."
  default     = "nonprod"
  type        = string
}

variable "location" {
  description = "Azure region."
  default     = "East US 2"
  type        = string
}

variable "sku_name" {
  description = "Coding Center application service plan size"
  default     = "S2"
  type        = string
}

variable "subnet_address_prefixes" {
  description = "Coding Center shared subnet address prefix"
  default     = ["10.105.134.192/26"]
  type        = list(string)
}

variable "tags" {
  description = "Tags to organize Azure resources."
  type        = map(string)
  default = {
    terraform = "true"
  }
}
