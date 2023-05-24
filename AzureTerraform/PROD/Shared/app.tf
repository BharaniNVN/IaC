resource "random_uuid" "data_gateway" {}

resource "azuread_application" "data_gateway" {
  display_name = local.application_name_data_gateway
  owners       = [data.azurerm_client_config.current.object_id]

  api {
    oauth2_permission_scope {
      admin_consent_description  = format("Allow the application to access %s on behalf of the signed-in user.", local.application_name_data_gateway)
      admin_consent_display_name = format("Access %s", local.application_name_data_gateway)
      enabled                    = true
      id                         = random_uuid.data_gateway.result
      type                       = "User"
      user_consent_description   = format("Allow the application to access %s on your behalf.", local.application_name_data_gateway)
      user_consent_display_name  = format("Access %s", local.application_name_data_gateway)
      value                      = "user_impersonation"
    }
  }

  web {
    homepage_url = format("https://%s", local.application_name_data_gateway)

    implicit_grant {
      access_token_issuance_enabled = false
      id_token_issuance_enabled     = true
    }
  }

  tags = ["terraform"]
}

resource "azuread_service_principal" "data_gateway" {
  application_id = azuread_application.data_gateway.application_id
  owners         = [data.azurerm_client_config.current.object_id]

  tags = ["terraform"]
}

resource "azuread_service_principal_password" "data_gateway" {
  service_principal_id = azuread_service_principal.data_gateway.id
  display_name         = "On premises data gateway"
  end_date             = "2099-01-01T01:01:01Z"
}
