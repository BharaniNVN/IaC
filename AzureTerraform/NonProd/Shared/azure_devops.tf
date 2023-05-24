resource "azurerm_resource_group" "azure_devops_agent_pools" {
  name     = "${local.prefix}-azure-devops-agent-pools-rg"
  location = var.location

  tags = merge(
    local.tags,
    {
      "resource" = "resource group"
    },
  )
}

resource "azurerm_virtual_network" "azure_devops_agent_pools" {
  name                = format("%s-azure-devops-agent-pools-vnet", local.prefix)
  location            = azurerm_resource_group.azure_devops_agent_pools.location
  address_space       = ["10.0.0.0/22"]
  resource_group_name = azurerm_resource_group.azure_devops_agent_pools.name

  tags = merge(
    local.tags,
    {
      "resource" = "virtual network"
    },
  )
}

resource "azurerm_subnet" "azure_devops_agent_pool_automation" {
  name                 = "automation"
  virtual_network_name = azurerm_virtual_network.azure_devops_agent_pools.name
  resource_group_name  = azurerm_resource_group.azure_devops_agent_pools.name
  address_prefixes     = ["10.0.0.0/27"]
}

/*module "azure_devops_agent_pool_test" {
  source = "../../../modules/terraform/azure_devops_agent_pool_vmss"

  resource_group_resource                 = azurerm_resource_group.azure_devops_agent_pools
  resource_prefix                         = local.prefix
  vmss_suffix                             = ["-az-automation"]
  boot_diagnostics_storage_account_suffix = "azmxhhpdiag"
  vmss_size                               = "Standard_DS2_v2"
  instances                               = 2
  overprovision                           = false
  platform_fault_domain_count             = 1
  priority                                = "Spot"
  single_placement_group                  = false
  subnet_resource                         = azurerm_subnet.azure_devops_agent_pool_automation
  image_publisher                         = "MicrosoftVisualStudio"
  image_offer                             = "visualstudio2019latest"
  image_sku                               = "vs-2019-ent-latest-ws2019"
  os_type                                 = "windows"
  computer_name_prefix                    = "az-auto"
  admin_username                          = var.local_admin_user
  admin_password                          = var.local_admin_pswd
  extension = [
    {
      "name"                       = "customScript"
      "publisher"                  = "Microsoft.Compute"
      "type"                       = "CustomScriptExtension"
      "type_handler_version"       = var.custom_script_extension_version
      "protected_settings"         = null
      "provision_after_extensions" = null
      "settings" = jsonencode({
        "fileUris" : [
          "https://proddscstg.blob.core.windows.net/scripts/AzureDevOps/InstallHelpers.ps1",
          "https://proddscstg.blob.core.windows.net/scripts/AzureDevOps/PathHelpers.ps1",
          "https://proddscstg.blob.core.windows.net/scripts/AzureDevOps/InstallChrome.ps1",
          "https://proddscstg.blob.core.windows.net/scripts/AzureDevOps/InstallNodejs.ps1",
          "https://proddscstg.blob.core.windows.net/scripts/AzureDevOps/InstallDotNet48.ps1",
          "https://proddscstg.blob.core.windows.net/scripts/AzureDevOps/Install.ps1"
        ],
        "commandToExecute" : "powershell -ExecutionPolicy Unrestricted -File ./AzureDevOps/Install.ps1"
      })
      
    }
  ]

  tags = local.tags
}*/

module "azure_devops_agent_pool_test02" {
  source = "../../../modules/terraform/azure_devops_agent_pool_vmss"

  resource_group_resource                 = azurerm_resource_group.azure_devops_agent_pools
  resource_prefix                         = local.prefix
  vmss_suffix                             = ["-az-vmss-vs2022"]
  boot_diagnostics_storage_account_suffix = "azmxhhpdiag02"
  vmss_size                               = "Standard_DS2_v2"
  instances                               = 2
  overprovision                           = false
  platform_fault_domain_count             = 1
  priority                                = "Spot"
  single_placement_group                  = false
  subnet_resource                         = azurerm_subnet.azure_devops_agent_pool_automation
  image_publisher                         = "MicrosoftVisualStudio"
  image_offer                             = "visualstudio2022"
  image_sku                               = "vs-2022-ent-latest-ws2022"
  os_type                                 = "windows"
  computer_name_prefix                    = "az-auto"
  admin_username                          = var.local_admin_user
  admin_password                          = var.local_admin_pswd
  extension = [
    {
      "name"                       = "customScript"
      "publisher"                  = "Microsoft.Compute"
      "type"                       = "CustomScriptExtension"
      "type_handler_version"       = var.custom_script_extension_version
      "protected_settings"         = null
      "provision_after_extensions" = null
      "settings" = jsonencode({
        "fileUris" : [
          "https://proddscstg.blob.core.windows.net/scripts/AzureDevOps/InstallHelpers.ps1",
          "https://proddscstg.blob.core.windows.net/scripts/AzureDevOps/PathHelpers.ps1",
          "https://proddscstg.blob.core.windows.net/scripts/AzureDevOps/InstallChrome.ps1",
          "https://proddscstg.blob.core.windows.net/scripts/AzureDevOps/InstallNodejs.ps1",
          "https://proddscstg.blob.core.windows.net/scripts/AzureDevOps/InstallDotNet48.ps1",
          "https://proddscstg.blob.core.windows.net/scripts/AzureDevOps/Install.ps1"
        ],
        "commandToExecute" : "powershell -ExecutionPolicy Unrestricted -File ./AzureDevOps/Install.ps1"
      })
      
    }
  ]

  tags = local.tags
}