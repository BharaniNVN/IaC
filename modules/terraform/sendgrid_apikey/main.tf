resource "null_resource" "this" {

  triggers = {
    "credentials"                    = var.management_api_key_value
    "file"                           = "sendgrid_apikey.json"
    "key_vault_id"                   = var.key_vault_id
    "name"                           = var.api_key_name
    "secret_name"                    = var.secret_name
    "force_sendgrid_apikey_redeploy" = var.force_sendgrid_apikey_redeploy
  }

  provisioner "local-exec" {
    command     = "$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop; $response = Invoke-RestMethod -Uri 'https://api.sendgrid.com/v3/api_keys' -Method Post -Headers @{Authorization=\"Bearer ${self.triggers.credentials}\"} -ContentType 'application/json' -Body '{\"name\":\"${self.triggers.name}\",\"scopes\":[\"mail.send\"]}' -TimeoutSec 30; $response | Select-Object -ExcludeProperty scopes | ConvertTo-Json | Out-File ${self.triggers.file}"
    interpreter = ["pwsh", "-command"]

    when = create
  }

  provisioner "local-exec" {
    command     = "$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop; $arg=@{Headers=@{Authorization=\"Bearer ${self.triggers.credentials}\"}; ContentType='application/json'}; $response = (Invoke-RestMethod -Uri 'https://api.sendgrid.com/v3/api_keys' -Method Get @arg -TimeoutSec 30).result.Where({$_.name -eq '${self.triggers.name}'}).api_key_id; if ($response.Count -gt 0) { if ($response.Count -gt 1) {throw \"More then one api key found with name '${self.triggers.name}' in the SendGrid portal. Please remove manually.\"} else {Invoke-RestMethod -Uri \"https://api.sendgrid.com/v3/api_keys/$response\" -Method Delete @arg -TimeoutSec 30}}"
    interpreter = ["pwsh", "-command"]

    when = destroy
  }
}

data "external" "this" {
  program = ["pwsh", "-command", "$result=@{}; (Get-Content ${null_resource.this.triggers.file} -ea SilentlyContinue | ConvertFrom-Json).PSObject.Properties.Foreach({$result[$_.Name]=$_.Value}); return $result|ConvertTo-Json"]

  depends_on = [null_resource.this]
}

resource "azurerm_key_vault_secret" "this" {
  name         = var.secret_name
  value        = data.external.this.result["api_key"]
  key_vault_id = var.key_vault_id
  content_type = "token"

  lifecycle {
    ignore_changes = [
      value
    ]
  }

  depends_on = [var.module_depends_on]
}
