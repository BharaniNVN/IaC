locals {
  application_name_web = format("%s-web-ad-app", var.deprecated_application_prefix)
  connection_string    = "Server=tcp:${azurerm_mssql_server.this.name}.database.windows.net,1433;Initial Catalog=${azurerm_mssql_database.this.name};Persist Security Info=False;User ID=${var.azure_sql_admin};Password=${var.azure_sql_admin_pswd};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  ingestion_endpoint   = "https://${azurerm_resource_group.this.location}-0.in.applicationinsights.azure.com/"
  deprecated_prefix    = lower(format("%s%s", var.environment, var.deprecated_application_prefix))
  homepage             = format("https://%s.%s", var.deprecated_application_prefix, data.terraform_remote_state.prod_shared.outputs.aad_domain_name)
  tags = merge(
    var.tags,
    {
      "application" = var.application
      "environment" = var.environment
    },
  )

}
