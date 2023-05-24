data "azurerm_automation_account" "this" {
  depends_on = [
    azurerm_automation_account.this
  ]
  name                = "${local.prefix}-automation-account"
  resource_group_name = local.resource_group_name
}