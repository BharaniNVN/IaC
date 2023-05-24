locals {
  location = coalesce(var.location, var.resource_group_resource["location"])
  # https://docs.microsoft.com/en-us/azure/azure-monitor/app/monitor-web-app-availability#azure
  locations = {
    "emea-au-syd-edge"  = ["Australia East", "australiaeast"]
    "latam-br-gru-edge" = ["Brazil South", "brazilsouth"]
    "us-fl-mia-edge"    = ["Central US", "centralus"]
    "apac-hk-hkn-azr"   = ["East Asia", "eastasia"]
    "us-va-ash-azr"     = ["East US", "eastus"]
    "emea-ch-zrh-edge"  = ["France South", "francesouth"]
    "emea-fr-pra-edge"  = ["France Central", "francecentral"]
    "apac-jp-kaw-edge"  = ["Japan East", "japaneast"]
    "emea-gb-db3-azr"   = ["North Europe", "northeurope"]
    "us-il-ch1-azr"     = ["North Central US", "northcentralus"]
    "us-tx-sn1-azr"     = ["South Central US", "southcentralus"]
    "apac-sg-sin-azr"   = ["Southeast Asia", "southeastasia"]
    "emea-se-sto-edge"  = ["UK West", "ukwest"]
    "emea-nl-ams-azr"   = ["West Europe", "westeurope"]
    "us-ca-sjc-azr"     = ["West US", "westus"]
    "emea-ru-msa-edge"  = ["UK South", "uksouth"]
  }
  permission_groups = {
    "authenticate_sdk_control_channel" = {
      read_permissions = ["agentconfig"]
    }
    "full_permissions" = {
      read_permissions  = ["agentconfig", "aggregate", "api", "draft", "extendqueries", "search"]
      write_permissions = ["annotations"]
    }
    "read_telemetry" = {
      read_permissions = ["aggregate", "api", "draft", "extendqueries", "search"]
    }
    "write_annotations" = {
      write_permissions = ["annotations"]
    }
  }
}

resource "azurerm_application_insights" "this" {
  name                                  = var.name
  location                              = local.location
  resource_group_name                   = var.resource_group_resource["name"]
  application_type                      = var.application_type
  daily_data_cap_in_gb                  = var.daily_data_cap_in_gb
  daily_data_cap_notifications_disabled = var.daily_data_cap_notifications_disabled
  disable_ip_masking                    = var.disable_ip_masking
  retention_in_days                     = var.retention_in_days
  sampling_percentage                   = var.sampling_percentage
  workspace_id                          = var.log_analytics_workspace_resource != null ? var.log_analytics_workspace_resource["id"] : null

  tags = merge(
    var.tags,
    {
      "resource" = "application insights"
    },
  )
}

resource "azurerm_application_insights_api_key" "this" {
  for_each = var.api_keys

  name                    = each.key
  application_insights_id = azurerm_application_insights.this.id
  read_permissions        = flatten([for i in each.value : lookup(local.permission_groups[i], "read_permissions", [])])
  write_permissions       = flatten([for i in each.value : lookup(local.permission_groups[i], "write_permissions", [])])
}

resource "random_uuid" "this" {
  for_each = var.web_tests
}

resource "azurerm_application_insights_web_test" "this" {
  for_each = var.web_tests

  name                    = each.key
  location                = local.location
  resource_group_name     = var.resource_group_resource["name"]
  application_insights_id = azurerm_application_insights.this.id
  description             = lookup(each.value, "description", "")
  enabled                 = true
  frequency               = lookup(each.value, "frequency", null)
  geo_locations = flatten(
    [for l in lookup(each.value, "geo_locations", [for k, v in local.locations : local.location if contains(v, local.location)]) :
      coalescelist([for k, v in local.locations : k if contains(v, l)], [l])
    ]
  )
  kind          = lookup(each.value, "kind", "ping")
  retry_enabled = lookup(each.value, "retry_enabled", false)
  timeout       = lookup(each.value, "timeout", 30)

  configuration = lookup(
    each.value,
    "configuration",
    format(
      <<-XML
        <WebTest Name="%s" Id="%s" CssProjectStructure="" CssIteration="" Timeout="%s" WorkItemIds="" xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010" Description="%s" CredentialUserName="" CredentialPassword="" PreAuthenticate="True" Proxy="default" StopOnError="False" RecordedResultFile="" ResultsLocale="">
          <Items>
            <Request Method="GET" Version="1.1" Url="%s" ThinkTime="%s" Timeout="%s" ParseDependentRequests="True" FollowRedirects="True" RecordResult="True" Cache="False" ResponseTimeGoal="0" Encoding="utf-8" ExpectedHttpStatusCode="%s" ExpectedResponseUrl="" ReportingName="" IgnoreHttpStatusCode="False" />
          </Items>
        </WebTest>
      XML
      , each.key, random_uuid.this[each.key].id, lookup(each.value, "timeout", 30), lookup(each.value, "description", ""),
      lookup(each.value, "url", ""), lookup(each.value, "think_time", 0), lookup(each.value, "timeout", 30), lookup(each.value, "expected_http_status_code", 200)
    )
  )

  tags = merge(
    var.tags,
    {
      format("hidden-link:%s", azurerm_application_insights.this.id) = "Resource"
      "resource"                                                     = "application_insights_web_test"
    },
  )
}
