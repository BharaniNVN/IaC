locals {
  application_name_api          = format("%s-api-ad-app", local.deprecated_application_prefix)
  application_name_web          = format("%s-web-ad-app", local.deprecated_application_prefix)
  deprecated_application_prefix = lower(split(" ", var.application)[0])
  deprecated_prefix             = lower(format("%s%s", var.environment, local.deprecated_application_prefix))
  homepage                      = format("https://%s.%s", local.deprecated_application_prefix, data.terraform_remote_state.prod_shared.outputs.aad_domain_name)
  tags = merge(
    var.tags,
    {
      "application" = var.application
      "environment" = var.environment
    },
  )
}
