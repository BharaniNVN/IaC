output "keyvaults_ids" {
  description = "Map of the managed and unmanaged keyvaults IDs in PROD environment for AFO product."
  value = {
    all            = azurerm_key_vault.all.id
    all_managed    = azurerm_key_vault.all_managed.id
    env2           = azurerm_key_vault.env2.id
    env2_managed   = azurerm_key_vault.env2_managed.id
    env4           = azurerm_key_vault.env4.id
    env4_managed   = azurerm_key_vault.env4_managed.id
    env5           = azurerm_key_vault.env5.id
    env5_managed   = azurerm_key_vault.env5_managed.id
    env6           = azurerm_key_vault.env6.id
    env6_managed   = azurerm_key_vault.env6_managed.id
    env7           = azurerm_key_vault.env7.id
    env7_managed   = azurerm_key_vault.env7_managed.id
    shared         = azurerm_key_vault.shared.id
    shared_managed = azurerm_key_vault.shared_managed.id
  }
}
