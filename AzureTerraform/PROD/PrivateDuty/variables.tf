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

variable "environment" {
  description = "Environment name."
  default     = "Prod"
  type        = string
}

variable "environment_prefix" {
  description = "Environment prefix to use."
  default     = "p"
  type        = string
}

variable "location" {
  description = "Azure region."
  default     = "Central US"
  type        = string
}

variable "solution_name" {
  description = "Name(s) of the solutions for Log Analytics workspace."
  default     = ["ApplicationInsights"]
  type        = list(string)
}

variable "tags" {
  description = "Tags to organize Azure resources."
  type        = map(string)
  default = {
    terraform = "true"
  }
}
