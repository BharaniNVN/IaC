data "template_file" "custom_script" {
  template = "${file("${path.module}/configuration/awx.sh.tpl")}"

  vars = {
    awx_admin_username           = var.awx_admin_username
    awx_admin_password           = var.awx_admin_password
    awx_secret_key               = var.awx_secret_key
    awx_database_name            = var.awx_database_name
    awx_version                  = var.awx_version
    awx_database_server_type     = var.awx_database_server_type
    awx_database_server_fqdn     = local.awx_database_server_fqdn
    awx_database_server_port     = var.awx_database_server_port
    awx_database_server_username = local.awx_database_server_username
    awx_database_server_password = var.awx_database_server_password
  }
}

data "azurerm_client_config" "current" {}
