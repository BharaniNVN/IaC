resource "azurerm_subnet" "caregiver_as" {
  name                 = "${local.prefix}-as-subnet"
  virtual_network_name = data.terraform_remote_state.nonprod_shared.outputs.vnet.name
  resource_group_name  = data.terraform_remote_state.nonprod_shared.outputs.vnet.resource_group_name
  address_prefixes     = ["10.105.139.192/27"]
}

resource "azurerm_subnet" "caregiver_paas" {
  name                 = "${local.prefix}-paas-subnet"
  virtual_network_name = data.terraform_remote_state.nonprod_shared.outputs.vnet.name
  resource_group_name  = data.terraform_remote_state.nonprod_shared.outputs.vnet.resource_group_name
  address_prefixes     = ["10.105.139.224/27"]
}
