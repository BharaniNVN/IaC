variable "name" {
  description = "List of names of the Hybrid Worker Groups that will be created"
  type        = set(string)
}

variable "automation_account_id" {
  description = "ID of the parent automation account"
  type        = string
}

variable "credential_name" {
  description = "Name of the Automation account credential. HWG will use default (SYSTEM) Run As account if not specified"
  type        = string
  default     = ""
}
