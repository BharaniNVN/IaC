provider "azurerm" {
  features {
    # TODO: unblock once fixed
    # application_insights {
    #   disable_generated_rule = true
    # }
  }
}
