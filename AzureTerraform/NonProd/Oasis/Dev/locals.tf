locals {
  application_name_api = format("%s-api-ad-app", local.deprecated_prefix)
  application_name_web = format("%s-web-ad-app", local.deprecated_prefix)
  deprecated_prefix    = lower(format("%s%s", var.environment_prefix, split(" ", var.application)[0]))
  homepage             = format("https://%s-as.%s", local.deprecated_prefix, data.terraform_remote_state.nonprod_shared.outputs.aad_domain_name)
  tags = merge(
    var.tags,
    {
      "application" = var.application
      "environment" = var.environment
    },
  )
}
