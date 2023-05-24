variable "company" {
  description = "Company name."
  default     = "MatrixCare HHH"
  type        = string
}

variable "env" {
  description = "Environment prefix to use."
  default     = "Prod"
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

variable "pipelines_agent_subnet_address_space" {
  description = "Pipelines agents (deployed in ACI) subnet address space."
  default     = ["10.105.72.32/28"]
  type        = list(string)
}

variable "pipelines_agent_virtual_network_address_space" {
  description = "Pipelines agents virtual network address space."
  default     = ["10.105.72.32/27"]
  type        = list(string)
}

variable "plan_name" {
  default     = "bronze"
  description = "SendGrid plan name."
  type        = string
}

variable "resource_prefix" {
  description = "The prefix used for all resources."
  default     = "mxhhptf"
  type        = string
}

variable "subscription_id" {
  description = "The Azure subscription in which the resources will be created in."
  default     = "0f67b021-5b3d-4f38-973a-8bcddde64f72"
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

variable "user_email" {
  description = "E-mail address of the SendGrid subscriber."
  default     = "hhhautomation@matrixcare.com"
  type        = string
}

variable "user_first_name" {
  description = "First name of the SendGrid subscriber."
  default     = "HHH"
  type        = string
}

variable "user_last_name" {
  description = "Last name of the SendGrid subscriber."
  default     = "Automation"
  type        = string
}
