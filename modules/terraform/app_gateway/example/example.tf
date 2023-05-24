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

resource "azurerm_subnet" "agw_waf_subnet" {
  name                 = "AGW"
  virtual_network_name = azurerm_virtual_network.this.name
  resource_group_name  = azurerm_resource_group.network.name
  address_prefixes     = ["10.0.2.224/27"]
}

resource "azurerm_resource_group" "this" {
  name     = "${var.env}-servers-rg"
  location = var.location
}

module "agw" {
  source = "../"

  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  resource_prefix               = "mxhhp"
  subnet_resource               = azurerm_subnet.agw_waf_subnet
  cookie_based_affinity         = "Disabled"
  connection_draining_timeout   = 300
  agw_probe_unhealthy_threshold = 3
  agw_probe_timeout             = 30
  agw_probe_interval            = 90
  agw_sku                       = "WAF_v2" # for WAFv1 use "WAF_Medium"
  agw_tier                      = "WAF_v2" # for WAFv1 use "WAF"
  agw_capacity                  = "2"
  waf_mode                      = "Detection"
  agw_private_ip_index          = 5         # if this is ommited, dynamic IP allocation will be used for Private IP.
  agw_listens_on                = "private" # Listeners will be connected to this FE configuration. Could be "private" or "public".

  fe_configs = [
    "public",
    "private",
  ]

  certificates = [
    {
      "name"                = "careanyware_com"
      "key_vault_id"        = var.key_vault_id_1
      "key_vault_secret_id" = var.certificate_careanyware
    },
    {
      "name"                = "brightree_net"
      "key_vault_id"        = var.key_vault_id_1
      "key_vault_secret_id" = var.certificate_brightree
    },
    {
      "name"                = "mxhhpdev_com"
      "key_vault_id"        = var.key_vault_id_2
      "key_vault_secret_id" = var.certificate_mxhhpdev
    },
  ]

  mappings = {
    "configextapi.careanyware.com" = {
      "pool_name"       = "hhpwf"
      "servers"         = ["192.168.2.50", "192.168.2.51"]
      "probe_path"      = "/api/ping"
      "minimum_servers" = 1
      "request_timeout" = 15
    },
    "extapi.careanyware.com" = {
      "pool_name"       = "hhpwf"
      "probe_path"      = "/ping"
      "minimum_servers" = 1
    },
    "gc.careanyware.com" = {
      "pool_name"       = "hhpwf"
      "probe_path"      = "/"
      "minimum_servers" = 1
    },
    "integextapi.careanyware.com" = {
      "pool_name"         = "hhpwf"
      "probe_path"        = "/api/ping"
      "probe_status_code" = ["401"]
      "probe_body_text"   = "The Brightree Partner Token is missing"
      "minimum_servers"   = 1
    },
    "integextwcf.careanyware.com" = {
      "pool_name"       = "hhpwf"
      "probe_path"      = "/services/pingtest.svc"
      "minimum_servers" = 1
    },
    "login.careanyware.com" = {
      "pool_name"       = "web"
      "servers"         = ["192.168.2.60", "192.168.2.61"]
      "probe_path"      = "/"
      "minimum_servers" = 1
    },
    "missioncontrol.careanyware.com" = { # This block is shows a configuration example when backend in a WebApp
      "pool_name"  = "hhpwf"
      "probe_path" = "/"
      "is_web_app" = ""                                           # If this keyname is present "Use for App service" in HTTP settings will be set. The value is not checked.
      "http_path"  = "/"                                          # Value for "Override backend path" in HTTP settings
      "servers"    = azurerm_app_service.as.default_site_hostname # Value of URL of the WebApp
    },
    "mobileapi.brightree.net"  = { "pool_name" = "cawws01", "servers" = ["10.0.0.91"] },
    "mobileapi2.brightree.net" = { "pool_name" = "sync01", "servers" = ["10.0.0.92"] },
    "mobileapi4.brightree.net" = { "pool_name" = "sync02", "servers" = ["10.0.0.93"] },
    "secure21.careanyware.com" = { "pool_name" = "afo21", "servers" = ["10.0.0.21"] },
    "secure22.careanyware.com" = { "pool_name" = "afo22", "servers" = ["10.0.0.22"] },
    "secure41.careanyware.com" = { "pool_name" = "afo41", "servers" = ["10.0.0.41"] },
    "secure42.careanyware.com" = { "pool_name" = "afo42", "servers" = ["10.0.0.42"] },
    "secure51.careanyware.com" = { "pool_name" = "afo51", "servers" = ["10.0.0.51"] },
    "secure52.careanyware.com" = { "pool_name" = "afo52", "servers" = ["10.0.0.52"] },
    "secure61.careanyware.com" = { "pool_name" = "afo61", "servers" = ["10.0.0.61"] },
    "secure62.careanyware.com" = { "pool_name" = "afo62", "servers" = ["10.0.0.62"] },
  }
}
