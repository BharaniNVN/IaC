resource "random_id" "api_jwt_key" {
  byte_length = 32
}

resource "random_id" "api_jwt_issuer" {
  byte_length = 32
}

resource "random_id" "api_jwt_audience" {
  byte_length = 32
}

resource "random_id" "gc_secret_key" {
  byte_length = 32
}

resource "random_id" "gc_issuer_key" {
  byte_length = 32
}

resource "random_id" "gc_audience_key" {
  byte_length = 32
}

resource "azuread_application" "gc_key_vault_authentication" {
  display_name     = "mxhhp-${local.prefix}-groundcontrol-kv-sp"
  owners           = [data.azurerm_client_config.current.object_id]
  sign_in_audience = "AzureADMyOrg"

  web {
    homepage_url  = local.domain_url
    redirect_uris = [format("%s/", local.domain_url)]

    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }

  tags = ["terraform"]
}

resource "azuread_service_principal" "gc_key_vault_authentication" {
  application_id               = azuread_application.gc_key_vault_authentication.application_id
  app_role_assignment_required = false
  owners                       = [data.azurerm_client_config.current.object_id]

  tags = ["terraform"]
}

resource "azuread_service_principal_password" "gc_key_vault_authentication" {
  service_principal_id = azuread_service_principal.gc_key_vault_authentication.id
  end_date_relative    = "86400h" # 86400h hours = 10 years
}
