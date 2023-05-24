locals {
  deprecated_prefix = lower(format("%s%s", var.deprecated_environment, var.application_prefix))
  tags = merge(
    var.tags,
    {
      "application" = var.application
      "environment" = var.environment
    },
  )
}
