resource "random_uuid" "securends" {}

resource "azuread_application" "securends" {
  display_name = local.application_name_securends
  owners       = [data.azurerm_client_config.current.object_id]

  api {
    oauth2_permission_scope {
      admin_consent_description  = format("Allow the application to access %s on behalf of the signed-in user.", local.application_name_securends)
      admin_consent_display_name = format("Access %s", local.application_name_securends)
      enabled                    = true
      id                         = random_uuid.securends.result
      type                       = "User"
      user_consent_description   = format("Allow the application to access %s on your behalf.", local.application_name_securends)
      user_consent_display_name  = format("Access %s", local.application_name_securends)
      value                      = "user_impersonation"
    }
  }

  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph

    resource_access {
      id   = data.azuread_service_principal.microsoft_graph.oauth2_permission_scope_ids["User.Read"]
      type = "Scope"
    }

    resource_access {
      id   = data.azuread_service_principal.microsoft_graph.oauth2_permission_scope_ids["User.Read.All"]
      type = "Scope"
    }

    resource_access {
      id   = data.azuread_service_principal.microsoft_graph.oauth2_permission_scope_ids["User.ReadBasic.All"]
      type = "Scope"
    }

    resource_access {
      id   = data.azuread_service_principal.microsoft_graph.oauth2_permission_scope_ids["Directory.AccessAsUser.All"]
      type = "Scope"
    }

    resource_access {
      id   = data.azuread_service_principal.microsoft_graph.oauth2_permission_scope_ids["Directory.Read.All"]
      type = "Scope"
    }

    resource_access {
      id   = data.azuread_service_principal.microsoft_graph.app_role_ids["User.Read.All"]
      type = "Role"
    }

    resource_access {
      id   = data.azuread_service_principal.microsoft_graph.app_role_ids["Directory.Read.All"]
      type = "Role"
    }
  }

  web {
    homepage_url = format("https://%s", local.application_name_securends)

    implicit_grant {
      access_token_issuance_enabled = false
      id_token_issuance_enabled     = true
    }
  }

  tags = ["terraform"]
}

resource "azuread_service_principal" "securends" {
  application_id = azuread_application.securends.application_id
  owners         = [data.azurerm_client_config.current.object_id]

  tags = ["terraform"]
}

resource "azuread_application_password" "securends" {
  application_object_id = azuread_application.securends.id
  end_date              = "2030-01-01T00:00:00Z"
}

resource "azurerm_key_vault_secret" "securends_app_id" {
  name         = "SecurEndsAppId"
  value        = azuread_application.securends.application_id
  key_vault_id = azurerm_key_vault.prod_shared_old.id

  tags = merge(
    local.tags,
    {
      "resource" = "key vault secret"
    },
  )
}

resource "azurerm_key_vault_secret" "securends_secret" {
  name         = "SecurEndsClientSecret"
  value        = azuread_application_password.securends.value
  key_vault_id = azurerm_key_vault.prod_shared_old.id

  tags = merge(
    local.tags,
    {
      "resource" = "key vault secret"
    },
  )
}
