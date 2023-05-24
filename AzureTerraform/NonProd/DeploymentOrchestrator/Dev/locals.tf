locals {
  prefix            = lower(format("%s%s%s", var.environment_prefix, var.application_prefix, var.application))
  connection_string = "Server=tcp:${var.sql_server_name},${var.sql_server_port};Initial Catalog=${var.sql_database};Persist Security Info=False;User ID=${var.sql_admin_user};Password=${var.sql_admin_pswd};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  connection_string_automation_api = "Server=tcp:${var.sql_server_name_automation_api},${var.sql_server_port};Initial Catalog=${var.sql_database};User ID=${var.sql_admin_user_automation_api};Password=${var.sql_admin_pswd_automation_api};"
  clinical_connection_string_automation_api = "Server=tcp:${var.clinical_sql_server_name_automation_api},${var.sql_server_port};Initial Catalog=${var.clinical_sql_database};User ID=${var.sql_admin_user_automation_api};Password=${var.sql_admin_pswd_automation_api};"
  tags = merge(
    var.tags,
    {
      "application" = var.application
      "environment" = var.environment
    },
  )
}