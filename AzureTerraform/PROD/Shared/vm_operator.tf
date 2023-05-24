resource "random_uuid" "vm_operator" {}

resource "azuread_application" "vm_operator" {
  display_name = local.application_name_vm_operator
  owners       = [data.azurerm_client_config.current.object_id]

  api {
    oauth2_permission_scope {
      admin_consent_description  = format("Allow the application to access %s on behalf of the signed-in user.", local.application_name_vm_operator)
      admin_consent_display_name = format("Access %s", local.application_name_vm_operator)
      enabled                    = true
      id                         = random_uuid.vm_operator.result
      type                       = "User"
      user_consent_description   = format("Allow the application to access %s on your behalf.", local.application_name_vm_operator)
      user_consent_display_name  = format("Access %s", local.application_name_vm_operator)
      value                      = "user_impersonation"
    }
  }

  web {
    homepage_url = format("https://%s", local.application_name_vm_operator)

    implicit_grant {
      access_token_issuance_enabled = false
      id_token_issuance_enabled     = true
    }
  }

  tags = ["terraform"]
}

resource "azuread_application_password" "vm_operator" {
  application_object_id = azuread_application.vm_operator.id
  end_date              = "2030-01-01T00:00:00Z"
}

resource "azuread_service_principal" "vm_operator" {
  application_id = azuread_application.vm_operator.application_id
  owners         = [data.azurerm_client_config.current.object_id]

  tags = ["terraform"]
}

resource "azurerm_role_definition" "vm_operator" {
  name        = "VM Operator"
  scope       = local.subscription_resource_id
  description = "This is a custom role used by Automation Account to start/stop virtual machines by schedule."

  permissions {
    actions = [
      "Microsoft.Compute/*/read",
      "Microsoft.Compute/virtualMachines/start/action",
      "Microsoft.Compute/virtualMachines/restart/action",
      "Microsoft.Compute/virtualMachines/deallocate/action"
    ]
    not_actions = []
  }

  assignable_scopes = [local.subscription_resource_id]
}

resource "azurerm_role_assignment" "vm_operator" {
  scope                = local.subscription_resource_id
  role_definition_name = azurerm_role_definition.vm_operator.name
  principal_id         = azuread_service_principal.vm_operator.id
}
