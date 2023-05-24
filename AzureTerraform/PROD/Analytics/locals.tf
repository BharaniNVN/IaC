locals {
  deprecated_prefix  = lower(format("%s%s", var.environment, var.application_prefix))
  internal_domain_dn = join(",", formatlist("DC=%s", split(".", var.internal_domain_name)))
  prefix             = lower(format("%s%s", var.environment_prefix, var.application_prefix))
  tags = merge(
    var.tags,
    {
      "application" = var.application
      "environment" = var.environment
    },
  )
}
