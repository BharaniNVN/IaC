locals {
  aad_domain_name       = data.terraform_remote_state.nonprod_shared.outputs.aad_domain_name
  application_name_auth = format("%s-ad-app", local.prefix)
  domain_dn             = join(",", formatlist("DC=%s", split(".", local.domain_name)))
  domain_name           = data.terraform_remote_state.nonprod_shared.outputs.domain_specifics.name
  domain_netbios_name   = data.terraform_remote_state.nonprod_shared.outputs.domain_specifics.netbiosname
  domain_url            = format("http://%s", local.aad_domain_name)
  external_domain_name  = data.terraform_remote_state.nonprod_shared.outputs.domain_specifics["external_name"]
  login_fqdn            = format("%s.%s", local.login_name, local.external_domain_name)
  login_name            = format("%s%s", local.sni_prefix, "login")
  login_url             = format("https://%s", local.login_fqdn)
  login_url_mx          = format("%s/account/mx1", local.login_url)
  prefix                = lower(format("%s%s", var.environment_prefix, var.application_prefix))
  sni_prefix            = contains(["dr", "p"], lower(var.environment_prefix)) ? "" : format("%s-", local.prefix)
  subnets               = { for s in [azurerm_subnet.internal, azurerm_subnet.dmz] : lower(s.name) => s.id }

  pipeline_variables_all = {
    # following variables are static ones which are different between some envs
    "cellTrakUrl"           = "https://interface.celltrak.net/"
    "mxhhpdevComThumbprint" = data.azurerm_app_service_certificate_order.mxhhpdev_com.signed_certificate_thumbprint
    "oktaBaseUrl"           = "(empty)"
    "oktaClientId"          = "(empty)"
    "oktaClientSecret"      = "(empty)"
    "oktaTokenEndpoint"     = "https://dev-877297.oktapreview.com/oauth2/ausfxj67hxwviFFzv0h7/.well-known/oauth-authorization-server"
    # following variables are "managed" candidates and were added manually into a keyvault
    # "appPoolUserPswd"
  }

  pipeline_variables_all_managed = {
    "afoApplicationInsightsConnectionString"           = module.application_insights_afo.connection_string
    "apiJwtAudience"                                   = random_id.api_jwt_audience.b64_std
    "apiJwtIssuer"                                     = random_id.api_jwt_issuer.b64_std
    "apiJwtKey"                                        = random_id.api_jwt_key.b64_std
    "appPoolUser"                                      = format("%s\\%s", local.domain_netbios_name, var.app_pool_account)
    "authApiEnvHostname"                               = format("%s%s.%s", local.sni_prefix, "authapi", local.external_domain_name)
    "authApiEnvIPAddress"                              = "All Unassigned"
    "authenticationConnectionString"                   = format("Server=%s;Database=%s;Trusted_Connection=True;MultipleActiveResultSets=true;", values(module.sql_shared.name_with_fqdn_and_port)[0], "Authentication")
    "azureAudience"                                    = tolist(azuread_application.this.identifier_uris)[0]
    "azureClientId"                                    = azuread_application.this.application_id
    "azureClientSecret"                                = azuread_application_password.this.value
    "azureRedirectUri"                                 = local.login_url_mx
    "environmentLookupConnectionString"                = format("Data Source=%s;Initial Catalog=%s;Integrated Security=SSPI;MultipleActiveResultSets=True;Connection Timeout=600;", values(module.sql_shared.name_with_fqdn_and_port)[0], "EnvironmentLookup")
    "groundcontrolApplicationInsightsConnectionString" = module.application_insights_gc.connection_string
    "groundcontrolAudienceKey"                         = random_id.gc_audience_key.b64_std
    "groundcontrolContentSecurityPolicy"               = format("default-src 'self' https://fonts.googleapis.com/ https://cdn.quilljs.com/ https://fonts.gstatic.com https://*.azure.com *.%s 'unsafe-inline'; object-src 'none'; script-src 'self';", local.external_domain_name)
    "groundcontrolIssuerKey"                           = random_id.gc_issuer_key.b64_std
    "groundcontrolKeyVaultAuthenticationClientId"      = azuread_service_principal.gc_key_vault_authentication.application_id
    "groundcontrolKeyVaultAuthenticationClientSecret"  = azuread_service_principal_password.gc_key_vault_authentication.value
    "groundcontrolKeyVaultName"                        = azurerm_key_vault.all_managed.name
    "groundcontrolKeyVaultSecretNameForSendGridApiKey" = module.sendgrid_apikey.key_vault_secret_name
    "groundcontrolSecretKey"                           = random_id.gc_secret_key.b64_std
    "groundcontrolSendGridReplyEmail"                  = "noreply@brightree.com"
    "groundcontrolWebUrl"                              = format("https://%s%s.%s", local.sni_prefix, "gc", local.external_domain_name)
    "hmeNetConnectionString"                           = format("Data Source=%s;Initial Catalog=%s;Integrated Security=SSPI;MultipleActiveResultSets=True;Connection Timeout=600;", values(module.sql_shared.name_with_fqdn_and_port)[0], "HMENET")
    "oktaRedirectUri"                                  = local.login_url_mx
    "redisConnectionString"                            = azurerm_redis_cache.redis.primary_connection_string
  }

  tags = merge(
    var.tags,
    {
      "application" = var.application
      "environment" = var.environment
    },
  )
}
