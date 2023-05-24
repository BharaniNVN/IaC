locals {
  deprecated_prefix = lower(format("%s%s", var.deprecated_environment_prefix, split(" ", var.application)[0]))
  tags = merge(
    var.tags,
    {
      "application" = var.application
      "environment" = var.environment
    },
  )
}
