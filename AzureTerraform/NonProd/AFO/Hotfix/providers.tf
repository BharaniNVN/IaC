provider "azurerm" {
  features {
    # TODO: unblock once fixed
    # application_insights {
    #   disable_generated_rule = true
    # }
    key_vault {
      purge_soft_deleted_certificates_on_destroy = false
      purge_soft_deleted_keys_on_destroy         = false
      purge_soft_deleted_secrets_on_destroy      = false
    }
  }
}
