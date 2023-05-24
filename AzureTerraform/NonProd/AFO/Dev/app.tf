resource "random_uuid" "auth" {}

resource "azuread_application" "this" {
  display_name     = local.application_name_auth
  identifier_uris  = [format("https://%s/%sauth", local.aad_domain_name, local.prefix)]
  owners           = [data.azurerm_client_config.current.object_id]
  sign_in_audience = "AzureADMultipleOrgs"

  api {
    oauth2_permission_scope {
      admin_consent_description  = format("Allow the application to access %s on behalf of the signed-in user.", local.application_name_auth)
      admin_consent_display_name = format("Access %s", local.application_name_auth)
      enabled                    = true
      id                         = random_uuid.auth.result
      type                       = "User"
      user_consent_description   = format("Allow the application to access %s on your behalf.", local.application_name_auth)
      user_consent_display_name  = format("Access %s", local.application_name_auth)
      value                      = "user_impersonation"
    }
  }

  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph

    resource_access {
      id   = data.azuread_service_principal.microsoft_graph.oauth2_permission_scope_ids["User.Read"]
      type = "Scope"
    }
  }

  web {
    homepage_url = local.login_url
    redirect_uris = [
      format("%s/", local.login_url),
      local.login_url_mx,
      format("https://%s/account/login", data.terraform_remote_state.nonprod_shared.outputs.analytics_appservices[lower(var.environment)]),
      format("https://%s/account/login", data.terraform_remote_state.nonprod_shared.outputs.analytics_appservices["int"])
    ]

    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }

  tags = ["terraform"]
}

resource "azuread_application_password" "this" {
  application_object_id = azuread_application.this.id
  end_date              = "2030-01-01T00:00:00Z"
}

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
