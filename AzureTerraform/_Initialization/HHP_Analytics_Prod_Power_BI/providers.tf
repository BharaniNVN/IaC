provider "azurerm" {
  subscription_id = var.subscription_id

  features {
    key_vault {
      purge_soft_deleted_certificates_on_destroy = false
      purge_soft_deleted_keys_on_destroy         = false
      purge_soft_deleted_secrets_on_destroy      = false
    }
  }
}
