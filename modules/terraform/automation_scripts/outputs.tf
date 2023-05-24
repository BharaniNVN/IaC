output "automation_account_name" {
  description = "Name of the Automation Account."
  value = azurerm_automation_account.this.name
}

output "automation_account_resource_group_name" {
  description = "Automation Account's Resource Group name."
  value = azurerm_automation_account.this.resource_group_name
}

output "automation_account_id" {
  description = "Automation Account's resource ID. Example: /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myResourceGroup/providers/Microsoft.Automation/automationAccounts/myAutomationAccount"
  value = azurerm_automation_account.this.id
}

output "automation_account_endpoint" {
  description = "Automation Account's URL endpoint. Example: https://00000000-0000-0000-0000-000000000000.agentsvc.ne.azure-automation.net/accounts/00000000-0000-0000-0000-000000000000."
  value = data.azurerm_automation_account.this.endpoint
}
