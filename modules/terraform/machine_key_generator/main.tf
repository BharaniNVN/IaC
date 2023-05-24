resource "null_resource" "this" {

  triggers = {
    "decryption_key_secret_name" = var.decryption_key_secret_name
    "decryption_method"          = var.decryption_method
    "file"                       = "machine_key.json"
    "key_vault_id"               = var.key_vault_id
    "validation_key_secret_name" = var.validation_key_secret_name
    "validation_method"          = var.validation_method
    "force_machine_key_redeploy" = var.force_machine_key_redeploy
  }

  provisioner "local-exec" {
    command = <<EOF
      #Requires -PSEdition Core
      $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

      . ${path.module}/scripts/helpers.ps1

      $parameters = @{
        DecryptionAlgorithm = '${self.triggers.decryption_method}'
        OutputType          = 'JSON'
        ValidationAlgorithm = '${self.triggers.validation_method}'
      }

      $machineKeysOutput = Initialize-MachineKey @parameters
      $machineKeysOutput | Out-File ${self.triggers.file}
    EOF

    interpreter = ["pwsh", "-command"]
  }
}

data "external" "this" {
  program = ["pwsh", "-command", "$result=@{}; (Get-Content ${null_resource.this.triggers.file} -ea SilentlyContinue | ConvertFrom-Json).PSObject.Properties.Foreach({$result[$_.Name]=$_.Value}); return $result|ConvertTo-Json"]

  depends_on = [null_resource.this]
}

resource "azurerm_key_vault_secret" "decryption_key" {
  name         = var.decryption_key_secret_name
  value        = data.external.this.result["DecryptionKey"]
  key_vault_id = var.key_vault_id

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "azurerm_key_vault_secret" "decryption_method" {
  name         = var.decryption_method_secret_name
  value        = var.decryption_method
  key_vault_id = var.key_vault_id
}

resource "azurerm_key_vault_secret" "validation_key" {
  name         = var.validation_key_secret_name
  value        = data.external.this.result["ValidationKey"]
  key_vault_id = var.key_vault_id

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "azurerm_key_vault_secret" "validation_method" {
  name         = var.validation_method_secret_name
  value        = var.validation_method
  key_vault_id = var.key_vault_id
}
