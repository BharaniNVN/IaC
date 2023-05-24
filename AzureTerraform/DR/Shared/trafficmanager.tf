resource "azurerm_resource_group" "trafficmanager" {
  name     = "${local.deprecated_prefix}-trafficmanager-rg"
  location = var.location

  tags = merge(
    local.tags,
    {
      "resource" = "resource group"
    },
  )
}

module "traffic_manager" {
  source = "../../../modules/terraform/traffic_manager/"

  prefix                  = "${local.deprecated_prefix}-"
  resource_group_name     = azurerm_resource_group.trafficmanager.name
  enable_azure_endpoints  = false
  enable_onprem_endpoints = false
  target_resource_id      = data.terraform_remote_state.shared.outputs.azure_firewall_public_ip_resource_dr_1.id

  profiles = {
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
    "secure71"       = "secure71.careanyware.com"
    "secure72"       = "secure72.careanyware.com"
    "secure81"       = "secure81.careanyware.com"
    "secure82"       = "secure82.careanyware.com"
    "mobileapi"      = "mobileapi.brightree.net"
    "mobileapi2"     = "mobileapi2.brightree.net"
    "mobileapi4"     = "mobileapi4.brightree.net"
    "mobileapi7"     = "mobileapi7.careanyware.com"
  }

  tags = local.tags
}
