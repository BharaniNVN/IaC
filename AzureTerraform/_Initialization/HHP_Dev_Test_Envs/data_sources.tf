data "azuread_application_published_app_ids" "well_known" {}

data "azuread_domains" "this" {
  only_default = true
}

data "azuread_group" "this" {
  for_each = var.groups

  display_name = each.value
}

data "azurerm_subscription" "primary" {}
