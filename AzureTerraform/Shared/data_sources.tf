data "azurerm_key_vault" "initial" {
  provider = azurerm.key_vault

  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group_name
}

data "azurerm_key_vault_secret" "pipelines_agent_subnet_resource" {
  provider = azurerm.key_vault

  name         = var.pipelines_agent_subnet_resource_secret_name
  key_vault_id = data.azurerm_key_vault.initial.id
}
