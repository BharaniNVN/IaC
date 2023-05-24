locals {
  #I couldn't retrieve Hybrid Worker URL from data source/PS/CLI output, so i'm constructing it myself by modifying DSC endpoint URL. 
  #It can be retrieved with REST API query though, so this can be an alternative approach
  hybrid_service_url = replace(replace(var.automation_account_endpoint, "agentsvc", "jrds"), "accounts", "automationAccounts")
}

resource "azurerm_virtual_machine_extension" "hybrid_worker" {
  for_each = var.virtual_machine_resource

  name                 = "HybridWorker"
  virtual_machine_id   = each.value
  publisher            = "Microsoft.Azure.Automation.HybridWorker"
  type                 = "HybridWorkerForWindows"
  type_handler_version = var.type_handler_version

  settings = <<SETTINGS
    {
        "AutomationAccountURL": "${local.hybrid_service_url}"
    }
  SETTINGS

  tags = merge(
    var.tags,
    {
      "resource" = "virtual machine extension"
    },
  )

  depends_on = [azurerm_resource_group_template_deployment.runbook_worker_associaton]
}

resource "azurerm_resource_group_template_deployment" "runbook_worker_associaton" {
  for_each = var.virtual_machine_resource

  name                = format("runbook_worker_association_%s", each.key)
  resource_group_name = var.automation_account_rg_name
  deployment_mode     = "Incremental"
  template_content    = file("${path.module}/worker_group_association.json")

  parameters_content = jsonencode({
    "automationAccount" = { "value" = var.automation_account_name },
    "workerGroupName"   = { "value" = var.worker_group_name == null ? each.key : var.worker_group_name }
    "virtualMachineId"  = { "value" = each.value }
  })

  tags = merge(
    var.tags,
    {
      "resource" = "resource group template deployment"
    },
  )

  depends_on = [var.module_depends_on]
}
