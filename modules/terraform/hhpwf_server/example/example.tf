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

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "this" {
  name = "resources-rg"
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "testloganalytics008"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
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
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_subnet" "dmz" {
  name                 = "dmz"
  virtual_network_name = azurerm_virtual_network.this.name
  resource_group_name  = azurerm_resource_group.network.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_key_vault" "this" {
  name                            = "${var.env}-keyvault-test"
  location                        = azurerm_resource_group.network.location
  resource_group_name             = azurerm_resource_group.network.name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  enabled_for_disk_encryption     = true
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  sku_name                        = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    certificate_permissions = [
      "create",
      "delete",
      "deleteissuers",
      "get",
      "getissuers",
      "import",
      "list",
      "listissuers",
      "managecontacts",
      "manageissuers",
      "setissuers",
      "update",
    ]

    key_permissions = [
      "backup",
      "create",
      "decrypt",
      "delete",
      "encrypt",
      "get",
      "import",
      "list",
      "purge",
      "recover",
      "restore",
      "sign",
      "unwrapKey",
      "update",
      "verify",
      "wrapKey",
    ]

    secret_permissions = [
      "backup",
      "delete",
      "get",
      "list",
      "purge",
      "recover",
      "restore",
      "set",
    ]
  }

  access_policy {
    tenant_id = azurerm_user_assigned_identity.this.tenant_id
    object_id = azurerm_user_assigned_identity.this.principal_id

    secret_permissions = [
      "get",
      "list",
    ]
  }

  # network_acls {
  #   default_action = "Deny"
  #   bypass         = "AzureServices"
  # }
}

resource "azurerm_key_vault_certificate" "wildcard_certificate_1" {
  name         = "wildcard-certificate-1"
  key_vault_id = azurerm_key_vault.this.id

  certificate {
    contents = filebase64("wildcard_certificate_1.pfx")
    password = var.certificate_password_brightree
  }

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = false
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }
  }
}

resource "azurerm_key_vault_certificate" "wildcard_certificate_2" {
  name         = "wildcard-certificate-2"
  key_vault_id = azurerm_key_vault.this.id

  certificate {
    contents = filebase64("wildcard_certificate_2.pfx")
    password = var.certificate_password_careanyware
  }

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = false
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }
  }
}

resource "azurerm_resource_group" "this" {
  name     = "${var.env}-servers-rg"
  location = var.location
}

resource "azurerm_user_assigned_identity" "this" {
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  name                = "${var.env}-uai"
}

module "wf" {
  source = "../"

  quantity                                                  = 2
  resource_group_resource                                   = azurerm_resource_group.this
  resource_prefix                                           = var.env
  virtual_machine_suffix                                    = ["-testwf"]
  subnet_resource                                           = azurerm_subnet.dmz
  dns_servers                                               = ["10.1.0.4"]
  vm_starting_ip                                            = 41
  vm_size                                                   = "Standard_D4s_v3"
  user_assigned_identity_ids                                = [azurerm_user_assigned_identity.this.id]
  enable_key_vault_certificates_integration_using_extension = true
  certificate_urls                                          = [azurerm_key_vault_certificate.wildcard_certificate_1.secret_id, azurerm_key_vault_certificate.wildcard_certificate_2.secret_id]
  key_vault_extension_version                               = { "windows" = "1.0", "linux" = "2.0" }
  key_vault_msi_client_id                                   = azurerm_user_assigned_identity.this.client_id
  dsc_extension_version                                     = "2.83"
  dsc_storage_container_resource                            = { name = "dsc", storage_account_name = "dscterraformtest", resource_group_name = data.azurerm_resource_group.this.name }
  enable_internal_loadbalancer                              = true
  # lb_sku                         = "Standard"
  lb_ip = 40
  # lb_enable_ha_ports             = true
  lb_rules = [
    { probe = { Tcp = 12345 }, rule = {} },
    { probe = { Tcp = 8900 }, rule = {} },
    { probe = { Http = 8080 }, rule = { Tcp = 8080 } },
    { probe = { Http = 80 }, rule = { Tcp = 80 } },
    { probe = { Https = 4443 }, rule = { Tcp = 4443 } },
    { probe = { Https = 443 }, rule = { Tcp = 443 } },
    { probe = { Http = 80 }, rule = { Udp = 80 } }
  ]
  lb_load_distribution = "SourceIP"
  admin_username       = "testadmin"
  admin_password       = "t3st@dm!nP@%%"
  domain_name          = "test.com"
  domain_join_account  = "administrator123"
  domain_join_password = "qpo)fleoc64Gssdopp"
  join_ou              = "OU=WF,OU=Azure,OU=Servers,DC=test,DC=com"
  local_groups_members = { "IIS_IUSRS" = ["test\\svc-web"] }
  # iis_folders_with_read_access     = ["C:\\TempIISRead"]
  # iis_folders_with_full_access     = ["C:\\TempIISFull"]
  app_pool_account = "svc-web"
  sql_aliases = [
    { target = "10.0.0.1,1433", name = ["BTHMENET", "Operational"] },
    { target = "10.0.0.3,1433", name = ["EnvironmentLookup", "Log"] },
    { target = "10.0.0.2,1433", name = ["Hangfire", "PRODSQL-2"] },
    { target = "10.0.0.4,1433", name = ["PRODSQL-4"] },
    { target = "10.0.0.5,1433", name = ["PRODSQL-5"] },
    { target = "10.0.0.6,1433", name = ["PRODSQL-6"] },
  ]
  hosts_entries                    = [{ "name" = "extapi.test.com", "ip" = "127.0.0.1" }]
  dns_records                      = [{ "name" = "extapi", "zone" = "test.com", "ip" = cidrhost(azurerm_subnet.dmz.address_prefixes[0], 40) }]
  log_analytics_workspace_resource = azurerm_log_analytics_workspace.this
  azure_devops_extension_version   = "1.27"
  azure_devops_account             = var.azure_devops_account
  azure_devops_project             = var.azure_devops_project
  azure_devops_deployment_group    = "TestGroup"
  azure_devops_agent_tags          = "HHPWF"
  azure_devops_pat_token           = var.azure_devops_pat_token
}

output "name" {
  value = module.wf.name
}

output "fqdn" {
  value = module.wf.fqdn
}

output "identity" {
  value = module.wf.identity
}

output "ip_address" {
  value = module.wf.ip_address
}

output "lb_ip_address" {
  value = module.wf.lb_ip_address
}

output "name_with_ip_address" {
  value = module.wf.name_with_ip_address
}

output "fqdn_with_ip_address" {
  value = module.wf.fqdn_with_ip_address
}
