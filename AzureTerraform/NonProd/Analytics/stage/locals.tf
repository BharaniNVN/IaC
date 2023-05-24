locals {
  deprecated_prefix  = lower(format("nonprod%s%s", var.environment, var.application_prefix))
  domain_dn          = join(",", formatlist("DC=%s", split(".", data.terraform_remote_state.nonprod_shared.outputs.domain_specifics_old.name)))
  deprecated_prefix2 = lower(format("%s%s", var.environment, var.application_prefix))
  prefix             = lower(format("%s%s", var.environment_prefix, var.application_prefix))
  tags = merge(
    var.tags,
    {
      "application" = var.application
      "environment" = var.environment
    },
  )
}
