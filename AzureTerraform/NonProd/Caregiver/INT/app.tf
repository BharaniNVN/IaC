resource "azurerm_service_plan" "this" {
  name                = "${local.prefix}-asp"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Windows"
  sku_name            = "S1"

  tags = merge(
    local.tags,
    {
      "resource" = "service plan"
    },
  )
}

resource "azurerm_windows_web_app" "app" {
  name                = "${local.prefix}-app"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  service_plan_id     = azurerm_service_plan.this.id
  app_settings        = data.external.app_web_app_appsettings.result

  site_config {
    always_on         = true
    default_documents = ["index.html"]
    ftps_state        = "Disabled"
    use_32_bit_worker = false

    ip_restriction {
      virtual_network_subnet_id = data.terraform_remote_state.nonprod_shared.outputs.agw_subnet_id
    }
  }

  tags = merge(
    local.tags,
    {
      "resource" = "windows web app"
    },
  )
}

resource "azurerm_windows_web_app" "api" {
  name                = "${local.prefix}-api"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  service_plan_id     = azurerm_service_plan.this.id
  app_settings        = data.external.api_web_app_appsettings.result

  site_config {
    always_on         = true
    ftps_state        = "Disabled"
    use_32_bit_worker = false

    application_stack {
      dotnet_version = "v4.0"
    }

    ip_restriction {
      virtual_network_subnet_id = data.terraform_remote_state.nonprod_shared.outputs.agw_subnet_id
    }
  }

  tags = merge(
    local.tags,
    {
      "resource" = "windows web app"
    },
  )
}
