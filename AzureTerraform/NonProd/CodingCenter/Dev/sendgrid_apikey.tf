module "sendgrid_apikey" {
  source = "../../../../modules/terraform/sendgrid_apikey"

  api_key_name             = format("%s-mail", local.deprecated_prefix)
  key_vault_id             = data.terraform_remote_state.codingcenter_shared.outputs.key_vault_id
  management_api_key_value = data.terraform_remote_state.nonprod_shared.outputs.sendgrid_management_api_key
  secret_name              = format("%s-mail-%s-apikey", local.deprecated_prefix, local.deprecated_prefix)
}
