variable "decryption_key_secret_name" {
  description = "Secret name in Azure Key Vault where decryption key value will be stored."
  default     = "decryptionKey"
  type        = string
}

variable "decryption_method" {
  description = "Decryption method value used for machine key generation. Possible values: \"AES\", \"DES\" and \"3DES\"."
  default     = "AES"
  type        = string
}

variable "decryption_method_secret_name" {
  description = "Secret name in Azure Key Vault where decryption method value will be stored."
  default     = "decryptionMethod"
  type        = string
}

variable "key_vault_id" {
  description = "ID of the Azure Key Vault resource where secret values will be stored."
  type        = string
}

variable "validation_key_secret_name" {
  description = "Secret name in Azure Key Vault where validation key value will be stored."
  default     = "validationKey"
  type        = string
}

variable "validation_method" {
  description = "Validation method value used for machine key generation. Possible values: \"MD5\", \"SHA1\", \"HMACSHA256\", \"HMACSHA384\" and \"HMACSHA512\"."
  default     = "HMACSHA256"
  type        = string
}

variable "validation_method_secret_name" {
  description = "Secret name in Azure Key Vault where validation method value will be stored."
  default     = "validationMethod"
  type        = string
}

variable "force_machine_key_redeploy" {
  description = <<EOF
                This is a debug variable necessary to force machine key redeployment. The module is generating transient
                issues and releases can get stuck if that happens. Infrastructure as Code release
                (https://dev.azure.com/MatrixCareHHP/HH/_releaseDefinition?definitionId=64&_a=definition-variables)
                has a corresponding variable which can be used to force machine_key_generator module redeployment.
                There's also an intermediate variable with the same name defined at the root DR AFO module.
                Hence there's a three-level chain of variables:
                1. Azure DevOps release variable
                2. DR AFO root module (/AzureTerraform/DR/AFO/variables.tf)
                3. machine_key_generator (this) module

                By default it's set to 0 and to initiate redeployment it can be changed to any other value.
                Each subsequent trigger requires a new value. IMPORTANT: There's one caveat, although a minor one.
                If the variable in specific release is updated to a new value and then a new release is created,
                the variable's value will be reset to 0. Thus, a new redeployment will be triggered.

                Because of this it should be used scarcely and only/mostly for debugging or emergency purposes.
                EOF
  default     = ""
  type        = string
}