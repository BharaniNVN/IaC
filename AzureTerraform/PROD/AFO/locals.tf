locals {
  aad_domain_name             = data.terraform_remote_state.prod_shared.outputs.aad_domain_name
  application_name_auth       = format("%s-ad-app", local.deprecated_prefix)
  application_name_mobile_api = lower(format("%s%s-ad-app", var.environment, "mobileapi"))
  cert_careanyware            = data.terraform_remote_state.prod_shared.outputs.certificates["careanyware_com"]
  # cert_sfsso_brightree_net      = data.terraform_remote_state.prod_shared.outputs.certificates["sfsso_brightree_net"]
  # cert_community_matrixcare_com = data.terraform_remote_state.prod_shared.outputs.certificates["community_matrixcare_com"]
  # cert_ehomecare_com            = data.terraform_remote_state.prod_shared.outputs.certificates["ehomecare_com"]
  deprecated_prefix = lower(format("%s%s", var.environment, var.application_prefix))
  dmz_domain        = data.terraform_remote_state.prod_shared.outputs.dmz_domain_specifics
  # dmz_domain_dn         = join(",", formatlist("DC=%s", split(".", local.dmz_domain["name"])))
  # dmz_subnet      = merge(local.dmz_subnet_temp, { "address_prefixes" = [local.dmz_subnet_temp["address_prefix"]] })
  # dmz_subnet_temp = local.subnets_list[index(local.subnets_list[*].name, "DMZ")]
  domain_url = format("http://%s", local.aad_domain_name)
  # dsc_storage_container = data.terraform_remote_state.prod_shared.outputs.dsc_storage_container
  external_domain_name = data.terraform_remote_state.prod_shared.outputs.dmz_domain_specifics["external_name"]
  # hosts_entries = [
  #   { "name" = "secure71.careanyware.com", "ip" = cidrhost(local.dmz_subnet.address_prefixes[0], var.afo7_lb_ip + 1) },
  #   { "name" = "secure72.careanyware.com", "ip" = cidrhost(local.dmz_subnet.address_prefixes[0], var.afo7_lb_ip + 2) },
  #   { "name" = "mobileapi.brightree.net", "ip" = "192.168.20.100" },
  #   { "name" = "mobileapi2.brightree.net", "ip" = "192.168.20.81" },
  #   { "name" = "mobileapi4.brightree.net", "ip" = "192.168.20.82" },
  #   { "name" = "login.careanyware.com", "ip" = "192.168.20.180" },
  #   { "name" = "extapi.careanyware.com", "ip" = "192.168.20.190" },
  #   { "name" = "authapi.careanyware.com", "ip" = "192.168.20.190" },
  # ]
  # internal_domain = data.terraform_remote_state.prod_shared.outputs.internal_domain_specifics
  # internal_domain_dn    = join(",", formatlist("DC=%s", split(".", local.internal_domain["name"])))
  # internal_subnet       = merge(local.internal_subnet_temp, { "address_prefixes" = [local.internal_subnet_temp["address_prefix"]] })
  # internal_subnet_temp = local.subnets_list[index(local.subnets_list[*].name, "Internal")]
  login_name = format("%s%s", local.sni_prefix, "login")
  login_url  = format("%s.%s", local.login_name, local.external_domain_name)
  prefix     = lower(format("%s%s", var.environment_prefix, var.application_prefix))
  sni_prefix = contains(["dr", "p"], lower(var.environment_prefix)) ? "" : format("%s-", local.prefix)
  # subnets_list      = tolist(data.terraform_remote_state.prod_shared.outputs.vnet.subnet)

  pipeline_variables_all = {
    # following variables are static ones which are different between some envs
    "careanywareComThumbprint" = data.azurerm_key_vault_certificate.careanyware_com.thumbprint
    "cellTrakUrl"              = "https://interface.celltrak.net/"
    "oktaBaseUrl"              = "(empty)"
    "oktaClientId"             = "(empty)"
    "oktaClientSecret"         = "(empty)"
    "oktaTokenEndpoint"        = "(empty)"
    # following variables are "managed" candidates and were added manually into a keyvault
    # "appPoolUserPswd"
  }

  pipeline_variables_all_managed = {
    "afoApplicationInsightsConnectionString"           = module.application_insights_afo.connection_string
    "apiJwtAudience"                                   = random_id.api_jwt_audience.b64_std
    "apiJwtIssuer"                                     = random_id.api_jwt_issuer.b64_std
    "apiJwtKey"                                        = random_id.api_jwt_key.b64_std
    "appPoolUser"                                      = format("%s\\\\%s", local.dmz_domain["netbiosname"], var.app_pool_account)
    "authApiEnvHostname"                               = format("%s%s.%s", local.sni_prefix, "authapi", local.external_domain_name)
    "authApiEnvIPAddress"                              = "All Unassigned"
    "authenticationConnectionString"                   = format("Server=%s;Database=%s;Trusted_Connection=True;MultipleActiveResultSets=true;", "192.168.10.15", "Authentication")
    "azureAudience"                                    = tolist(azuread_application.auth.identifier_uris)[0]
    "azureClientId"                                    = azuread_application.auth.application_id
    "azureClientSecret"                                = azuread_application_password.auth.value
    "azureRedirectUri"                                 = format("https://%s/account/mx1", local.login_url)
    "environmentLookupConnectionString"                = format("Data Source=%s;Initial Catalog=%s;Integrated Security=SSPI;MultipleActiveResultSets=True;", "192.168.10.15", "EnvironmentLookup")
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
    "hmeNetConnectionString"                           = format("Data Source=%s;Initial Catalog=%s;Integrated Security=SSPI;MultipleActiveResultSets=True;", "192.168.10.15", "HMENET")
    "oktaRedirectUri"                                  = format("https://%s/account/mx1", local.login_url)
    # "redisConnectionString"                            = azurerm_redis_cache.redis.primary_connection_string
  }

  pipeline_variables_env2 = {
    # following variables are static ones which are different between some envs
    # following variables are "managed" candidates and were added manually into a keyvault
  }

  pipeline_variables_env2_managed = {
  }

  pipeline_variables_env4 = {
    # following variables are static ones which are different between some envs
    # following variables are "managed" candidates and were added manually into a keyvault
  }

  pipeline_variables_env4_managed = {
  }

  pipeline_variables_env5 = {
    # following variables are static ones which are different between some envs
    # following variables are "managed" candidates and were added manually into a keyvault
  }

  pipeline_variables_env5_managed = {
  }

  pipeline_variables_env6 = {
  }

  pipeline_variables_env6_managed = {
  }

  pipeline_variables_env7 = {
    # following variables are static ones which are different between some envs
    # following variables are "managed" candidates and were added manually into a keyvault
  }

  pipeline_variables_env7_managed = {
  }

  pipeline_variables_shared = {
    # following variables are static ones which are different between some envs
    # following variables are "managed" candidates and were added manually into a keyvault
  }

  pipeline_variables_shared_managed = {
  }

  tags = merge(
    var.tags,
    {
      "environment" = var.environment,
      "application" = var.application
    },
  )
}
