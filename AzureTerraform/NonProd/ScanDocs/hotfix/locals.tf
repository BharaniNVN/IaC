locals {
  deprecated_prefix = lower(format("nonprod%s%s", var.application_prefix, var.environment))
  tags = merge(
    var.tags,
    {
      "application" = var.application
      "environment" = var.environment
    },
  )
}
