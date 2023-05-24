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
  default     = "Prod"
}

# variable "environment_prefix" {
#   description = "Environment prefix to use."
#   default     = "p"
# }

variable "file_shares" {
  description = "A list of file shares for ScanDocs storage account"
  default     = ["prod2", "prod4", "prod5", "prod6"]
  type        = list(string)
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
