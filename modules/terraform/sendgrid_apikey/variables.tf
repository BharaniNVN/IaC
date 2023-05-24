variable "api_key_name" {
  description = "API key name."
  type        = string
}

variable "api_key_username" {
  description = "SendGrid API key username."
  default     = "apikey"
}

variable "key_vault_id" {
  description = "ID of the Azure Key Vault resource where API key value will be stored."
  type        = string
}

variable "management_api_key_value" {
  description = "SendGrid management API key value (the one with ability to create/remove api keys)."
  type        = string
}

variable "secret_name" {
  description = "Secret name in Azure Key Vault where SendGrid API key value will be stored."
  type        = string
}

variable "module_depends_on" {
  description = "Names of resources this module should depend upon."
  default     = null
  type        = any
}

variable "force_sendgrid_apikey_redeploy" {
  description = <<EOF
                This is a debug variable necessary to force sendgrid_apikey redeployment. The module is generating transient
                issues and releases can get stuck if that happens. Infrastructure as Code release
                (https://dev.azure.com/MatrixCareHHP/HH/_releaseDefinition?definitionId=64&_a=definition-variables)
                has a corresponding variable which can be used to force sendgrid_apikey module redeployment.
                There's also an intermediate variable with the same name defined at the root DR AFO module.
                Hence there's a three-level chain of variables:
                1. Azure DevOps release variable
                2. DR AFO root module (/AzureTerraform/DR/AFO/variables.tf)
                3. sendgrid_apikey (this) module

                By default it's set to 0 and to initiate redeployment it can be changed to any other value.
                Each subsequent trigger requires a new value. IMPORTANT: There's one caveat, although a minor one.
                If the variable in specific release is updated to a new value and then a new release is created,
                the variable's value will be reset to 0. Thus, a new redeployment will be triggered.

                Because of this it should be used scarcely and only/mostly for debugging or emergency purposes.
                EOF
  default     = ""
  type        = string
}