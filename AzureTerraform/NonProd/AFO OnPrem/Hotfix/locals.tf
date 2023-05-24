locals {
  application_name_auth       = format("%s-ad-app", local.deprecated_prefix)
  application_name_mobile_api = format("%s%s-ad-app", local.deprecated_partial_prefix, "mobileapi")
  deprecated_partial_prefix   = lower(format("nonprod%s", var.environment_prefix))
  deprecated_prefix           = lower(format("%s%s", local.deprecated_partial_prefix, var.application_prefix))
  tags = merge(
    var.tags,
    {
      "application" = var.application
      "environment" = var.environment
    },
  )
}
