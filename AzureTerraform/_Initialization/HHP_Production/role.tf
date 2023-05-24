resource "azurerm_role_definition" "this" {
  name        = "IAC Contributor"
  scope       = data.azurerm_subscription.primary.id
  description = "This is a custom role used by Terraform service principal."

  permissions {
    actions = ["*"]
    not_actions = [
      "Microsoft.Authorization/classicAdministrators/delete",
      "Microsoft.Authorization/classicAdministrators/write",
      "Microsoft.Authorization/denyAssignments/delete",
      "Microsoft.Authorization/denyAssignments/write",
      "Microsoft.Authorization/locks/delete",
      # "Microsoft.Authorization/locks/write",
      "Microsoft.Authorization/policies/audit/action",
      "Microsoft.Authorization/policies/auditIfNotExists/action",
      "Microsoft.Authorization/policies/deny/action",
      "Microsoft.Authorization/policies/deployIfNotExists/action",
      # "Microsoft.Authorization/policyAssignments/delete",
      # "Microsoft.Authorization/policyAssignments/write",
      "Microsoft.Authorization/policyDefinitions/delete",
      "Microsoft.Authorization/policyDefinitions/write",
      "Microsoft.Authorization/policySetDefinitions/delete",
      "Microsoft.Authorization/policySetDefinitions/write",
      # "Microsoft.Authorization/roleAssignments/delete",
      # "Microsoft.Authorization/roleAssignments/write",
      # "Microsoft.Authorization/roleDefinitions/delete",
      # "Microsoft.Authorization/roleDefinitions/write",
      "Microsoft.Authorization/elevateAccess/Action",
      "Microsoft.Blueprint/blueprintAssignments/write",
      "Microsoft.Blueprint/blueprintAssignments/delete",
    ]
  }

  assignable_scopes = [data.azurerm_subscription.primary.id]
}

resource "azurerm_role_assignment" "this" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = azurerm_role_definition.this.name
  principal_id         = azuread_service_principal.terraform.id
}
