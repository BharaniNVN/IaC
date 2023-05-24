provider "azurerm" {
  features {
    # TODO: unblock once fixed
    # application_insights {
    #   disable_generated_rule = true
    # }
    template_deployment {
      delete_nested_items_during_deletion = false # due to https://github.com/hashicorp/terraform-provider-azurerm/issues/9458
    }
  }
}
