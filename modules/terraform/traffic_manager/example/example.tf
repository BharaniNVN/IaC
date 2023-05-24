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

resource "azurerm_resource_group" "this" {
  name     = "${var.env}-trafficmanager-rg"
  location = var.location
}

resource "azurerm_public_ip" "test" {
  name                = "TestPublicIp1"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  domain_name_label   = "${var.env}-testuniquetf"
}

module "TrafficManager01" {
  source = "../"

  prefix                  = "mxhhp-"
  resource_group_name     = azurerm_resource_group.this.name
  enable_onprem_endpoints = true
  eanble_azure_endpoints  = false

  # Required for all Azure endpoints. Should be .id of Azure resource external traffic to be routed during disaster. {default} = .id of Application Gateway
  # target_resource_id = azurerm_public_ip.test.id

  profiles = {
    # A list of names/IPs of externally published resources. Must follow [Profile_name] = [Target FQDN] syntax. IP adresses are NOT allowed"

    "configextapi"   = "configextapi.careanyware.com"
    "extapi"         = "extapi.careanyware.com"
    "gc"             = "gc.careanyware.com"
    "integextapi"    = "integextapi.careanyware.com"
    "integextwcf"    = "integextwcf.careanyware.com"
    "login"          = "login.careanyware.com"
    "missioncontrol" = "missioncontrol.careanyware.com"
    "secure21"       = "secure21.careanyware.com"
    "secure22"       = "secure22.careanyware.com"
    "secure41"       = "secure41.careanyware.com"
    "secure42"       = "secure42.careanyware.com"
    "secure43"       = "secure43.careanyware.com"
    "secure51"       = "secure51.careanyware.com"
    "secure52"       = "secure52.careanyware.com"
    "secure53"       = "secure53.careanyware.com"
    "secure61"       = "secure61.careanyware.com"
    "secure62"       = "secure62.careanyware.com"
  }
}
