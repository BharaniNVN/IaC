provider "azurerm" {
  features {
    # TODO: unblock once fixed
    # application_insights {
    #   disable_generated_rule = true
    # }
    # TODO: remove once upper block is working
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
