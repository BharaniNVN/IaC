locals {
  aad_domain_name               = data.terraform_remote_state.dr_shared.outputs.aad_domain_name
  cert_careanyware              = data.terraform_remote_state.dr_shared.outputs.certificates["careanyware_com"]
  cert_community_matrixcare_com = data.terraform_remote_state.dr_shared.outputs.certificates["community_matrixcare_com"]
  dmz_domain                    = data.terraform_remote_state.dr_shared.outputs.dmz_domain_specifics
  dmz_domain_dn                 = join(",", formatlist("DC=%s", split(".", local.dmz_domain.name)))
  dmz_subnet                    = merge(local.dmz_subnet_temp, { "address_prefixes" = [local.dmz_subnet_temp["address_prefix"]] })
  dmz_subnet_temp               = local.subnets_list[index(local.subnets_list[*].name, "DMZ")]
  domain_url                    = format("http://%s", local.aad_domain_name)
  dsc_storage_container         = data.terraform_remote_state.dr_shared.outputs.dsc_storage_container
  external_domain_name          = data.terraform_remote_state.dr_shared.outputs.dmz_domain_specifics["external_name"]
  internal_domain               = data.terraform_remote_state.dr_shared.outputs.internal_domain_specifics
  internal_domain_dn            = join(",", formatlist("DC=%s", split(".", local.internal_domain.name)))
  internal_subnet               = merge(local.internal_subnet_temp, { "address_prefixes" = [local.internal_subnet_temp["address_prefix"]] })
  internal_subnet_temp          = local.subnets_list[index(local.subnets_list[*].name, "Internal")]
  login_fqdn                    = format("%s.%s", local.login_name, local.external_domain_name)
  login_name                    = format("%s%s", local.sni_prefix, "login")
  login_url                     = format("https://%s", local.login_fqdn)
  login_url_mx                  = format("%s/account/mx1", local.login_url)
  prefix                        = lower(format("%s%s", var.environment_prefix, var.application_prefix))
  sni_prefix                    = contains(["dr", "p"], lower(var.environment_prefix)) ? "" : format("%s-", local.prefix)
  subnets_list                  = tolist(data.terraform_remote_state.dr_shared.outputs.vnet.subnet)
  hosts_entries = [
    { "name" = "secure21.careanyware.com", "ip" = cidrhost(local.dmz_subnet.address_prefixes[0], var.afo2_vm_starting_ip) },
    { "name" = "secure22.careanyware.com", "ip" = cidrhost(local.dmz_subnet.address_prefixes[0], var.afo2_vm_starting_ip + 1) },
    { "name" = "secure41.careanyware.com", "ip" = cidrhost(local.dmz_subnet.address_prefixes[0], var.afo4_vm_starting_ip) },
    { "name" = "secure42.careanyware.com", "ip" = cidrhost(local.dmz_subnet.address_prefixes[0], var.afo4_vm_starting_ip + 1) },
    { "name" = "secure51.careanyware.com", "ip" = cidrhost(local.dmz_subnet.address_prefixes[0], var.afo5_vm_starting_ip) },
    { "name" = "secure52.careanyware.com", "ip" = cidrhost(local.dmz_subnet.address_prefixes[0], var.afo5_vm_starting_ip + 1) },
    { "name" = "secure61.careanyware.com", "ip" = cidrhost(local.dmz_subnet.address_prefixes[0], var.afo6_vm_starting_ip) },
    { "name" = "secure62.careanyware.com", "ip" = cidrhost(local.dmz_subnet.address_prefixes[0], var.afo6_vm_starting_ip + 1) },
    { "name" = "secure71.careanyware.com", "ip" = cidrhost(local.dmz_subnet.address_prefixes[0], var.afo7_vm_starting_ip) },
    { "name" = "secure72.careanyware.com", "ip" = cidrhost(local.dmz_subnet.address_prefixes[0], var.afo7_vm_starting_ip + 1) },
    { "name" = "secure81.careanyware.com", "ip" = cidrhost(local.dmz_subnet.address_prefixes[0], var.afo8_vm_starting_ip) },
    { "name" = "secure82.careanyware.com", "ip" = cidrhost(local.dmz_subnet.address_prefixes[0], var.afo8_vm_starting_ip + 1) },
    { "name" = "login.careanyware.com", "ip" = cidrhost(local.dmz_subnet.address_prefixes[0], var.login_lb_ip) },
    { "name" = "extapi.careanyware.com", "ip" = cidrhost(local.dmz_subnet.address_prefixes[0], var.wf_lb_ip) },
  ]

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
    "authenticationConnectionString"                   = format("Server=%s;Database=%s;Trusted_Connection=True;MultipleActiveResultSets=true;", values(module.sql_shared.name_with_fqdn_and_port)[0], "Authentication")
    "azureRedirectUri"                                 = local.login_url_mx
    "environmentLookupConnectionString"                = format("Data Source=%s;Initial Catalog=%s;Integrated Security=SSPI;MultipleActiveResultSets=True;", values(module.sql_shared.name_with_fqdn_and_port)[0], "EnvironmentLookup")
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
    "hmeNetConnectionString"                           = format("Data Source=%s;Initial Catalog=%s;Integrated Security=SSPI;MultipleActiveResultSets=True;", values(module.sql_shared.name_with_fqdn_and_port)[0], "HMENET")
    "oktaRedirectUri"                                  = local.login_url_mx
    "redisConnectionString"                            = azurerm_redis_cache.redis.primary_connection_string
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
    # following variables are static ones which are different between some envs
    # following variables are "managed" candidates and were added manually into a keyvault
  }

  pipeline_variables_env6_managed = {
  }

  pipeline_variables_env7 = {
    # following variables are static ones which are different between some envs
    # following variables are "managed" candidates and were added manually into a keyvault
  }

  pipeline_variables_env7_managed = {
  }

  pipeline_variables_env8 = {
    # following variables are static ones which are different between some envs
    # following variables are "managed" candidates and were added manually into a keyvault
  }

  pipeline_variables_env8_managed = {
  }

  pipeline_variables_shared = {
    # following variables are static ones which are different between some envs
    # following variables are "managed" candidates and were added manually into a keyvault
  }

  pipeline_variables_shared_managed = {
  }

  prod_secrets_all_managed = toset([
    "azureAudience",
    "azureClientId",
    "azureClientSecret",
  ])

  # Since nested for_each loops are not supported in resources this construct has to be used.
  # The structure of this local value looks like this (list of objects):
  # [{
  #   "storage_id": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/dummy-rg/providers/Microsoft.Storage/storageAccounts/dummy1sa",
  #   "vm_name": "drafo-dummy21"
  # },
  # {
  #   "storage_id": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/dummy-rg/providers/Microsoft.Storage/storageAccounts/dummy2sa",
  #   "vm_name": "drafo-dummy21"
  # }]
  # It's used by:
  # hybrid_worker_backup_storage_reader, hybrid_worker_backup_storage_key_operator
  # located in /AzureTerraform/DR/AFO/resources.tf
  sql_shared_db_restore_rbac_map = distinct(flatten([
    for sk, sv in data.terraform_remote_state.dr_shared.outputs.onprem_db_backup_storage_account_ids : [
      for sql_vm_name in module.sql_shared.name : {
        storage_id = sv
        vm_name    = sql_vm_name
      }
    ]
  ]))

  sql2_db_restore_rbac_map = distinct(flatten([
    for sk, sv in data.terraform_remote_state.dr_shared.outputs.onprem_db_backup_storage_account_ids : [
      for sql_vm_name in module.sql2.name : {
        storage_id = sv
        vm_name    = sql_vm_name
      }
    ]
  ]))

  sql4_db_restore_rbac_map = distinct(flatten([
    for sk, sv in data.terraform_remote_state.dr_shared.outputs.onprem_db_backup_storage_account_ids : [
      for sql_vm_name in module.sql4.name : {
        storage_id = sv
        vm_name    = sql_vm_name
      }
    ]
  ]))

  sql5_db_restore_rbac_map = distinct(flatten([
    for sk, sv in data.terraform_remote_state.dr_shared.outputs.onprem_db_backup_storage_account_ids : [
      for sql_vm_name in module.sql5.name : {
        storage_id = sv
        vm_name    = sql_vm_name
      }
    ]
  ]))

  sql6_db_restore_rbac_map = distinct(flatten([
    for sk, sv in data.terraform_remote_state.dr_shared.outputs.onprem_db_backup_storage_account_ids : [
      for sql_vm_name in module.sql6.name : {
        storage_id = sv
        vm_name    = sql_vm_name
      }
    ]
  ]))

  sql7_db_restore_rbac_map = distinct(flatten([
    for sk, sv in data.terraform_remote_state.dr_shared.outputs.onprem_db_backup_storage_account_ids : [
      for sql_vm_name in module.sql7.name : {
        storage_id = sv
        vm_name    = sql_vm_name
      }
    ]
  ]))

  sql8_db_restore_rbac_map = distinct(flatten([
    for sk, sv in data.terraform_remote_state.dr_shared.outputs.onprem_db_backup_storage_account_ids : [
      for sql_vm_name in module.sql8.name : {
        storage_id = sv
        vm_name    = sql_vm_name
      }
    ]
  ]))

  tags = merge(
    var.tags,
    {
      "application" = var.application
      "environment" = var.environment
    },
  )
}
