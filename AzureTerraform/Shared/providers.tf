provider "azurerm" {
  auxiliary_tenant_ids = [var.remote_tenant_id]

  features {}
}

provider "azurerm" {
  alias = "key_vault"

  features {}
}
