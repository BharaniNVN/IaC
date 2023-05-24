locals {
  domain_name          = data.terraform_remote_state.nonprod_shared.outputs.domain_specifics.name
  domain_netbios_name  = data.terraform_remote_state.nonprod_shared.outputs.domain_specifics.netbiosname
  domain_dn            = join(",", formatlist("DC=%s", split(".", local.domain_name)))
  external_domain_name = data.terraform_remote_state.nonprod_shared.outputs.domain_specifics["external_name"]

  pipeline_variables_all = {
    # following variables are "managed" candidates and were added manually into a keyvault
  }

  pipeline_variables_all_managed = {
    "apiFQDN"                          = format("%s%s.%s", local.sni_prefix, "api", local.external_domain_name)
    "appFQDN"                          = format("%s%s.%s", local.sni_prefix, "app", local.external_domain_name)
    "authFQDN"                         = format("%s%s.%s", local.sni_prefix, "auth", local.external_domain_name)
    "clickonceFQDN"                    = format("%s%s.%s", local.sni_prefix, "clickonce", local.external_domain_name)
    "codeSigningCertificateThumbprint" = data.azurerm_key_vault_certificate.code_signing_matrixcare.thumbprint
    "idmApiFQDN"                       = format("%s%s.%s", local.sni_prefix, "idm-api", local.external_domain_name)
    "managementFQDN"                   = format("%s%s.%s", local.sni_prefix, "management", local.external_domain_name)
    "mgmtinterfaceFQDN"                = format("%s%s.%s", local.sni_prefix, "mgmtinterface", local.external_domain_name)
    "ssrsServiceAccountUsername"       = format("%s\\%s", local.domain_netbios_name, var.ssrs_service_account)
    "ssrsServiceAccountPassword"       = var.ssrs_service_password
    "ssrsSQLInitAccountUsername"       = format("%s\\%s", local.domain_netbios_name, var.ssrs_sql_server_user)
    "ssrsSQLInitAccountPassword"       = var.ssrs_sql_server_pswd
    "reportsFQDN"                      = format("%s%s.%s", local.sni_prefix, "reports", local.external_domain_name)
    "telephonyApiFQDN"                 = format("%s%s.%s", local.sni_prefix, "telephony-api", local.external_domain_name)
    "telephonyServiceFQDN"             = format("%s%s.%s", local.sni_prefix, "telephony-service", local.external_domain_name)
    "clickonceHistoricFQDN"            = format("%s%s.%s", local.sni_prefix, "clickonce-historic", local.external_domain_name)
    "clickonceRegressionFQDN"          = format("%s%s.%s", local.sni_prefix, "clickonce-regression", local.external_domain_name)
    "clickonceReleaseFQDN"             = format("%s%s.%s", local.sni_prefix, "clickonce-release", local.external_domain_name)
    "websiteCertificateThumbprint"     = data.azurerm_app_service_certificate_order.mxhhpdev_com.signed_certificate_thumbprint
  }

  prefix     = lower(format("%s%s", var.environment_prefix, var.application_prefix))
  sni_prefix = contains(["dr", "p"], lower(var.environment_prefix)) ? "" : format("%s-", local.prefix)

  tags = merge(
    var.tags,
    {
      "application" = var.application
      "environment" = var.environment
    },
  )
}
