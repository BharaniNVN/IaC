locals {
  application_name_api = format("%s-api-ad-app", local.prefix)
  application_name_web = format("%s-web-ad-app", local.prefix)
  prefix               = lower(format("%s%s", var.environment_prefix, var.application_prefix))
  homepage             = format("https://%s-as.%s", local.prefix, data.terraform_remote_state.nonprod_shared.outputs.aad_domain_name)
  tags = merge(
    var.tags,
    {
      "application" = var.application
      "environment" = var.environment
    },
  )
}
