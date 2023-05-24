locals {
  prefix = lower(format("%s%s%s", var.environment_prefix, var.application_prefix, var.application))
  tags = merge(
    var.tags,
    {
      "application" = var.application
      "environment" = var.environment
    },
  )
}