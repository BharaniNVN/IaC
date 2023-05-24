resource "azuread_application" "terraform" {
  display_name     = "${var.env}-terraform"
  identifier_uris  = [format("https://%s/terraform", local.aad_domain)]
  owners           = local.aad_groups_members
  sign_in_audience = "AzureADMultipleOrgs"

  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result.AzureActiveDirectoryGraph

    resource_access {
      id   = "824c81eb-e3f8-4ee6-8f6d-de7f50d565b7" #Application permission: Application.ReadWrite.OwnedBy 
      type = "Role"
    }

    resource_access {
      id   = "78c8a3c8-a07e-4b9e-af1b-b5ccab50a175" #Application permission: Directory.ReadWrite.All 
      type = "Role"
    }
  }

  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph

    resource_access {
      id   = "18a4783c-866b-4cc7-a460-3d5e5662c884" #Application permission: Application.ReadWrite.OwnedBy 
      type = "Role"
    }

    resource_access {
      id   = "19dbc75e-c2e2-444c-a770-ec69d8559fc7" #Application permission: Directory.ReadWrite.All 
      type = "Role"
    }
  }

  web {
    implicit_grant {
      access_token_issuance_enabled = true
    }
  }

  tags = ["terraform"]
}

resource "azuread_service_principal" "terraform" {
  application_id = azuread_application.terraform.application_id
  owners         = local.aad_groups_members

  tags = ["terraform"]
}

resource "azuread_application" "container_registry" {
  display_name     = format("%s-containerregistry", var.env)
  owners           = local.aad_groups_members
  sign_in_audience = "AzureADMyOrg"

  web {
    implicit_grant {
      access_token_issuance_enabled = true
    }
  }

  tags = ["terraform"]
}

resource "azuread_service_principal" "container_registry" {
  application_id = azuread_application.container_registry.application_id
  owners         = local.aad_groups_members

  tags = ["terraform"]
}

resource "azuread_service_principal_password" "container_registry" {
  service_principal_id = azuread_service_principal.container_registry.id
}

resource "azurerm_role_assignment" "container_registry" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPush"
  principal_id         = azuread_service_principal.container_registry.id
}

resource "azuread_service_principal" "azure_active_directory_graph" {
  application_id = data.azuread_application_published_app_ids.well_known.result.AzureActiveDirectoryGraph
  owners         = distinct(concat(local.aad_groups_members, [azuread_service_principal.terraform.id]))
  use_existing   = true

  tags = ["terraform"]
}

resource "azuread_service_principal" "microsoft_graph" {
  application_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
  owners         = distinct(concat(local.aad_groups_members, [azuread_service_principal.terraform.id]))
  use_existing   = true

  tags = ["terraform"]
}
