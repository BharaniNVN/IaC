terraform {
  required_version = ">= 0.12.26"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "network" {
  name     = "${var.env}-network-rg"
  location = var.location
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet"
  location            = azurerm_resource_group.network.location
  address_space       = ["10.0.0.0/22"]
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  virtual_network_name = azurerm_virtual_network.this.name
  resource_group_name  = azurerm_resource_group.network.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_resource_group" "this" {
  name     = "${var.env}-server-rg"
  location = var.location
}

module "vmss" {
  source = "../"

  resource_group_resource  = azurerm_resource_group.this
  resource_prefix          = var.env
  vmss_suffix              = ["-testvmss"]
  vmss_size                = "Standard_DS3_v2"
  overprovision            = false
  os_disk_caching          = "ReadOnly"
  os_managed_disk_type     = "Standard_LRS"
  os_disk_size_gb          = 127
  enable_ephemeral_os_disk = true
  # priority                 = "Spot"
  single_placement_group = false
  subnet_resource        = azurerm_subnet.internal
  image_publisher        = "MicrosoftVisualStudio"
  image_offer            = "visualstudio2019latest"
  image_sku              = "vs-2019-ent-latest-ws2019"
  os_type                = "windows"
  # dns_servers              = ["10.1.0.4"]
  computer_name_prefix = "testvmss"
  admin_username       = "testadmin"
  admin_password       = "t3st@dm!nP@%%"
  extension = [
    {
      "name"                       = "customScript"
      "publisher"                  = "Microsoft.Compute"
      "type"                       = "CustomScriptExtension"
      "type_handler_version"       = "1.10"
      "protected_settings"         = null
      "provision_after_extensions" = null
      "settings" = jsonencode({
        "fileUris" : [
          "https://proddscstg.blob.core.windows.net/scripts/AzureDevOps/InstallHelpers.ps1",
          "https://proddscstg.blob.core.windows.net/scripts/AzureDevOps/InstallChrome.ps1",
          "https://proddscstg.blob.core.windows.net/scripts/AzureDevOps/InstallNodejs.ps1",
          "https://proddscstg.blob.core.windows.net/scripts/AzureDevOps/Install.ps1"
        ],
        "commandToExecute" : "powershell -ExecutionPolicy Unrestricted -File ./AzureDevOps/Install.ps1"
      })
    }
  ]
}

output "ostype" {
  value = module.vmss.os_type
}

output "first" {
  value = module.vmss.first
}

output "name" {
  value = module.vmss.name
}

output "id" {
  value = module.vmss.id
}

output "lb_ip_address" {
  value = module.vmss.lb_ip_address
}
