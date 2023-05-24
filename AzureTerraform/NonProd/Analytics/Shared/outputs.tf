output "sendgrid_apikey_username" {
  description = "SendGrid SMTP server connection account user name."
  value       = module.sendgrid_apikey.sendgrid_api_key_username
}

output "sendgrid_apikey_pswd" {
  description = "SendGrid SMTP server connection account password."
  value       = module.sendgrid_apikey.sendgrid_api_key_value
  sensitive   = true
}
