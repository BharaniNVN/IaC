output "db_backups_storage_account_id" {
  description = "Object ID of the DB backups shared storage account."
  value       = azurerm_storage_account.this.id
}

output "db_backups_uai_id" {
  description = "User Assigned Identity ID"
  value       = azurerm_user_assigned_identity.db_backups.id
}
