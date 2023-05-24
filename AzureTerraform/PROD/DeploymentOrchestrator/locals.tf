locals {
  prefix            = lower(format("%s%s%s", var.environment_prefix, var.application_prefix, var.application))
  connection_string = "Server=tcp:${var.sql_server_name},${var.sql_server_port};Initial Catalog=${var.sql_database};Persist Security Info=False;User ID=${var.sql_user};Password=${var.sql_pswd};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;"
  tags = merge(
    var.tags,
    {
      "application" = var.application
      "environment" = var.environment
    },
  )
}