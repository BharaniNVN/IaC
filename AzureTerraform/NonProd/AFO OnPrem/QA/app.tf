resource "random_uuid" "auth" {}

resource "azuread_application" "auth" {
  display_name     = local.application_name_auth
  identifier_uris  = [format("https://%s/%sauth", data.terraform_remote_state.nonprod_shared.outputs.aad_domain_name, lower(var.environment))]
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
    homepage_url = format("https://%slogin.ehomecare.com", lower(var.environment_prefix))
    redirect_uris = [
      format("https://%slogin.ehomecare.com/", lower(var.environment_prefix)),
      format("https://%slogin.ehomecare.com/account/mx1", lower(var.environment_prefix)),
      format("https://%s/account/login", data.terraform_remote_state.nonprod_shared.outputs.analytics_appservices["stage"]),
    ]

    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }
}

resource "azuread_application_password" "auth" {
  application_object_id = azuread_application.auth.id
  end_date              = "2030-01-01T00:00:00Z"
}

resource "random_uuid" "mobile_api" {}

resource "azuread_application" "mobile_api" {
  display_name                   = local.application_name_mobile_api
  fallback_public_client_enabled = true
  identifier_uris                = [format("https://%s/mobileapi/%sauth", data.terraform_remote_state.nonprod_shared.outputs.aad_domain_name, lower(var.environment))]
  owners                         = [data.azurerm_client_config.current.object_id]
  sign_in_audience               = "AzureADMultipleOrgs"

  api {
    oauth2_permission_scope {
      admin_consent_description  = format("Allow the application to access %s on behalf of the signed-in user.", local.application_name_mobile_api)
      admin_consent_display_name = format("Access %s", local.application_name_mobile_api)
      enabled                    = true
      id                         = random_uuid.mobile_api.result
      type                       = "User"
      user_consent_description   = format("Allow the application to access %s on your behalf.", local.application_name_mobile_api)
      user_consent_display_name  = format("Access %s", local.application_name_mobile_api)
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

  public_client {
    redirect_uris = [
      "com.matrixcare.hhho.aides.${lower(var.environment)}-azuread-signin://callback",
      "com.matrixcare.hhho.communicate.${lower(var.environment)}-azuread-signin://callback",
      "com.matrixcare.hhho.mobile.${lower(var.environment)}-azuread-signin://callback",
    ]
  }

  web {
    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }
}
