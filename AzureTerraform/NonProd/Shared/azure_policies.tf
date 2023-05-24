resource "azurerm_subscription_policy_assignment" "builtin" {
  for_each = var.builtin_azure_policy_definition_names

  description          = data.azurerm_policy_definition.builtin[each.key].description
  display_name         = data.azurerm_policy_definition.builtin[each.key].display_name
  location             = var.location
  name                 = data.azurerm_policy_definition.builtin[each.key].name
  policy_definition_id = data.azurerm_policy_definition.builtin[each.key].id
  subscription_id      = local.subscription_resource_id

  parameters = <<PARAMETERS
    {
      "eventHubRuleId": {
        "value": "${azurerm_eventhub_namespace_authorization_rule.alienvault.id}"
      },
      "profileName": {
        "value": "${format("setByPolicy%s%s", local.separator, data.azurerm_policy_definition.builtin[each.key].name)}"
      }
    }
  PARAMETERS

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "builtin" {
  for_each = merge(flatten([[
    for k, v in data.azurerm_policy_definition.builtin : { for i in jsondecode(v.policy_rule).then.details.roleDefinitionIds : format("%s%s%s", k, local.separator, split("/", i)[4]) => i }
  ]])...)

  scope              = azurerm_subscription_policy_assignment.builtin[split(local.separator, each.key)[0]].subscription_id
  role_definition_id = format("%s%s", azurerm_subscription_policy_assignment.builtin[split(local.separator, each.key)[0]].subscription_id, each.value)
  principal_id       = azurerm_subscription_policy_assignment.builtin[split(local.separator, each.key)[0]].identity[0].principal_id
}

resource "azurerm_subscription_policy_remediation" "builtin" {
  for_each = var.builtin_azure_policy_definition_names

  name                    = azurerm_subscription_policy_assignment.builtin[each.key].name
  subscription_id         = azurerm_subscription_policy_assignment.builtin[each.key].subscription_id
  policy_assignment_id    = azurerm_subscription_policy_assignment.builtin[each.key].id
  resource_discovery_mode = "ReEvaluateCompliance"
}
