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

provider "external" {
  version = "~> 1.2"
}

data "external" "azure_devops_agent_ip" {
  program = ["pwsh", "-command", "& { $vars=ConvertFrom-Json $([Console]::In.ReadLine()); $ip = $(Invoke-RestMethod https://ifconfig.co -Headers @{\"User-Agent\"=\"curl/7.58.0\"} -TimeoutSec 30) -replace '[^0-9.]'; $sa = az storage account list --query \"[?name=='$($vars.name)']\" -o json --only-show-errors 2>&1 | ConvertFrom-Json; if ($LASTEXITCODE) { throw $sa } elseif ($error.Count) { exit 1 }; if ($sa.Count -eq 1 -and (az storage share exists --account-name $sa.name --name non-existent --only-show-errors 2>&1) -match 'AuthorizationFailure') {az storage account network-rule add -g $sa.resourceGroup --account-name $sa.name --ip-address $ip -o none; while ((az storage share exists --account-name $sa.name --name non-existent --only-show-errors 2>&1) -match 'AuthorizationFailure') { Start-Sleep -Seconds 5; }}; return '{}' }"]

  query = {
    "name" = azurerm_storage_account.this.name
  }
}

resource "azurerm_resource_group" "this" {
  name     = "${var.env}-resources-rg3"
  location = "North Central US"
}

resource "azurerm_resource_group" "network" {
  name     = "${var.env}-network-rg3"
  location = var.location
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet"
  location            = azurerm_resource_group.network.location
  address_space       = ["10.4.4.0/23"]
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_subnet" "this" {
  name                                           = "test"
  virtual_network_name                           = azurerm_virtual_network.this.name
  resource_group_name                            = azurerm_resource_group.network.name
  address_prefixes                               = ["10.4.5.32/27"]
  service_endpoints                              = ["Microsoft.Storage"]
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_storage_account" "this" {
  name                      = "dscterraformtest123"
  resource_group_name       = azurerm_resource_group.this.name
  location                  = azurerm_resource_group.this.location
  account_tier              = "Standard"
  account_kind              = "StorageV2"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true

  provisioner "local-exec" {
    command = "az storage account keys renew -g ${self.resource_group_name} -n ${self.name} --key-type kerb --key primary -o none && az storage account keys renew -g ${self.resource_group_name} -n ${self.name} --key-type kerb --key secondary -o none"
  }
}

resource "azurerm_network_interface" "this" {
  name                = "nic-test"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_servers         = ["10.10.10.10"]

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(azurerm_subnet.this.address_prefixes[0], 10)
  }
}

resource "azurerm_storage_share" "this" {
  name                 = "share"
  storage_account_name = azurerm_storage_account.this.name
  quota                = 50

  depends_on = [data.external.azure_devops_agent_ip]
}

resource "azurerm_storage_share_directory" "root" {
  name                 = "root"
  share_name           = azurerm_storage_share.this.name
  storage_account_name = azurerm_storage_account.this.name
}

resource "azurerm_storage_share_directory" "error" {
  name                 = "root/error"
  share_name           = azurerm_storage_share.this.name
  storage_account_name = azurerm_storage_share_directory.root.storage_account_name
}

resource "azurerm_storage_account_network_rules" "this" {
  storage_account_id = azurerm_storage_account.this.id

  default_action             = "Deny"
  ip_rules                   = []
  virtual_network_subnet_ids = [azurerm_subnet.this.id]
  bypass                     = ["Logging", "Metrics"]

  depends_on = [azurerm_storage_share_directory.error]
}

module "private_endpoint" {
  source = "../"

  resource_group_resource = azurerm_resource_group.this
  subnet_resource         = azurerm_subnet.this
  resource                = azurerm_storage_account.this
  endpoint                = "blob"
  ip_index                = 5
}

module "private_endpoint_file" {
  source = "../"

  resource_group_resource = azurerm_resource_group.this
  subnet_resource         = azurerm_subnet.this
  resource                = azurerm_storage_account.this
  endpoint                = "file"
  ip_index                = 11
  module_depends_on       = [module.private_endpoint, azurerm_network_interface.this]
}

output "file_name" {
  value = module.private_endpoint_file.name
}

output "file_ip_address" {
  value = module.private_endpoint_file.private_ip_address
}

output "blob_name" {
  value = module.private_endpoint.name
}

output "blob_ip_address" {
  value = module.private_endpoint.private_ip_address
}
