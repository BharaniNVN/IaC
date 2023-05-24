variable "env" {
  description = "Environment prefix to use."
  default     = "Analytics"
  type        = string
}

variable "groups" {
  description = "List of Azure AD groups which should have the access to the initial Azure Key Vault and created applications."
  default     = ["AzureSoftservCont", "KeyVaultManagement"]
  type        = set(string)
}

variable "location" {
  description = "Azure region."
  default     = "North Central US"
  type        = string
}

variable "resource_prefix" {
  description = "The Prefix used for all resources"
  default     = "mxhhptf"
  type        = string
}

variable "subscription_id" {
  description = "The Azure Subscription in which the resources will be created in"
  default     = "b4193425-c4d7-46eb-9064-9d2d20e3aa14"
  type        = string
}

variable "tags" {
  description = "Tags to organize Azure resources."
  type        = map(string)
  default = {
    application = "TerraformInitialization"
    terraform   = "true"
  }
}
