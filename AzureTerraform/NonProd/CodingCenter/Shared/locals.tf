locals {
  deprecated_prefix = lower(format("%s%s", var.deprecated_environment_prefix, var.deprecated_application_prefix))
  tags = merge(
    var.tags,
    {
      "application" = var.application
      "environment" = var.environment
    },
  )
}
