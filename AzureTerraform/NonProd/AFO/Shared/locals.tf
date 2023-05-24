locals {
  prefix = lower(format("%s%s", var.environment_prefix, var.application_prefix))
  tags = merge(
    var.tags,
    {
      "application" = var.application
      "environment" = var.environment
    },
  )
}
