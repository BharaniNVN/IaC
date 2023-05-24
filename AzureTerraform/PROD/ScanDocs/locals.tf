locals {
  deprecated_prefix = lower(format("%s%s", var.environment, var.application_prefix))
  subnets_list      = tolist(data.terraform_remote_state.prod_shared.outputs.vnet.subnet)
  dmz_subnet_id     = local.subnets_list[index(local.subnets_list[*].name, "DMZ")].id
  tags = merge(
    var.tags,
    {
      "application" = var.application
      "environment" = var.environment
    },
  )
}
