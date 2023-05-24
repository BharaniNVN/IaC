locals {
  application_name_web = format("%s-web-ad-app", local.deprecated_prefix)
  connection_string    = "Server=tcp:${azurerm_mssql_server.this.name}.database.windows.net,1433;Initial Catalog=${azurerm_mssql_database.this.name};Persist Security Info=False;User ID=${var.azure_sql_admin};Password=${var.azure_sql_admin_pswd};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  deprecated_prefix    = lower(format("%s%s", var.environment_prefix, var.deprecated_application_prefix))
  homepage             = format("https://%s-as.%s", local.deprecated_prefix, data.terraform_remote_state.nonprod_shared.outputs.aad_domain_name)
  
  subnet               = toset(flatten(var.subnet_ids))
  tags = merge(
    var.tags,
    {
      "application" = var.application
      "environment" = var.environment
    },
  )
}
