output "sas_token" {
  description = "Storage account-level SAS token with specified validity period."
  value       = data.azurerm_storage_account_blob_container_sas.this.sas
}

output "url" {
  description = "Key-value pairs which define urls to obtain archived DSC configuration for specific VMs."
  value       = { for k, v in azurerm_storage_blob.configuration : k == "" ? "default" : k => v.id }
}

output "hashsum" {
  description = "Calculated hashsum of the zip file, either was done before for the content or now for the archive file."
  value       = coalesce(local.calculated_hashsum, local.md5)
}
