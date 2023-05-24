resource "azuread_application" "vm_operator" {
  display_name = "${var.env}-vm_operator"
}

resource "random_password" "vm_operator" {
  length = 24

  keepers = {
    application_object_id = azuread_application.vm_operator.id
  }
}

resource "azuread_application_password" "vm_operator" {
  application_object_id = azuread_application.vm_operator.id
  value                 = random_password.vm_operator.result
  end_date              = "2030-01-01T00:00:00Z"
}

resource "azuread_service_principal" "vm_operator" {
  application_id = azuread_application.vm_operator.application_id
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
