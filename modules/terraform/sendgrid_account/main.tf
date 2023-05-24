locals {
  location            = var.resource_group_resource != null ? coalesce(var.location, var.resource_group_resource["location"]) : azurerm_resource_group.this[0].location
  password            = var.account_password != null ? var.account_password : random_password.this[0].result
  resource_group_name = var.resource_group_resource != null ? coalesce(var.resource_group_name, var.resource_group_resource["name"]) : azurerm_resource_group.this[0].name
  template_password   = var.key_vault_resource == null ? jsonencode({ "value" = local.password }) : jsonencode({ "reference" = { "keyVault" = { "id" = var.key_vault_resource["id"] }, "secretName" = azurerm_key_vault_secret.password[0].name } })
}

resource "azurerm_marketplace_agreement" "this" {
  publisher = var.plan_publisher
  offer     = var.plan_product
  plan      = var.plan_name
}

resource "azurerm_resource_group" "this" {
  count = var.resource_group_resource == null ? 1 : 0

  name     = var.resource_group_name
  location = var.location

  tags = merge(
    var.tags,
    {
      "resource" = "resource group"
    },
  )
}

resource "random_password" "this" {
  count = var.account_password == null ? 1 : 0

  length = var.account_password_length
}

resource "azurerm_resource_group_template_deployment" "this" {
  name                = "SendGrid"
  resource_group_name = local.resource_group_name
  deployment_mode     = "Incremental"
  template_content    = file("${path.module}/sendgrid-account.json")

  parameters_content = jsonencode({
    "acceptMarketingEmails" = { "value" = var.accept_marketing_emails },
    "company"               = { "value" = var.company },
    "email"                 = { "value" = var.user_email },
    "firstName"             = { "value" = var.user_first_name },
    "lastName"              = { "value" = var.user_last_name },
    "location"              = { "value" = local.location },
    "name"                  = { "value" = var.name },
    "password"              = jsondecode(local.template_password),
    "plan_name"             = { "value" = azurerm_marketplace_agreement.this.plan },
    "plan_product"          = { "value" = azurerm_marketplace_agreement.this.offer },
    "plan_promotion_code"   = { "value" = var.plan_promotion_code },
    "plan_publisher"        = { "value" = azurerm_marketplace_agreement.this.publisher },
    "tags"                  = { "value" = merge(var.tags, { "resource" = "sendgrid account" }) },
    "website"               = { "value" = var.website },
  })

  tags = merge(
    var.tags,
    {
      "resource" = "resource group template deployment"
    },
  )
}

resource "azurerm_key_vault_secret" "password" {
  count = var.key_vault_resource != null ? 1 : 0

  name         = var.key_vault_secret_name_account_password
  value        = local.password
  key_vault_id = var.key_vault_resource["id"]
  content_type = "Password"

  tags = merge(
    var.tags,
    {
      "resource" = "key vault secret"
    },
  )
}

resource "azurerm_key_vault_secret" "server_name" {
  count = var.key_vault_resource != null ? 1 : 0

  name         = var.key_vault_secret_name_server_name
  value        = jsondecode(azurerm_resource_group_template_deployment.this.output_content)["server_name"]["value"]
  key_vault_id = var.key_vault_resource["id"]

  tags = merge(
    var.tags,
    {
      "resource" = "key vault secret"
    },
  )
}

resource "azurerm_key_vault_secret" "username" {
  count = var.key_vault_resource != null ? 1 : 0

  name         = var.key_vault_secret_name_account_username
  value        = jsondecode(azurerm_resource_group_template_deployment.this.output_content)["username"]["value"]
  key_vault_id = var.key_vault_resource["id"]
  content_type = "Username"

  tags = merge(
    var.tags,
    {
      "resource" = "key vault secret"
    },
  )
}
