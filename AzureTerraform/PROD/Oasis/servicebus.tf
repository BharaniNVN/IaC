resource "azurerm_servicebus_namespace" "this" {
  name                = "${local.deprecated_prefix}-sb-ns"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"

  tags = merge(
    local.tags,
    {
      "resource" = "servicebus namespace"
    }
  )
}

resource "azurerm_monitor_diagnostic_setting" "servicebus" {
  name                       = "SendAllToLogAnalytics"
  target_resource_id         = azurerm_servicebus_namespace.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  dynamic "log" {
    for_each = {
      "ApplicationMetricsLogs" = false,
      "OperationalLogs"        = true,
      "RuntimeAuditLogs"       = true,
      "VNetAndIPFilteringLogs" = false,
    }

    content {
      category = log.key
      enabled  = log.value

      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = false

    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_servicebus_queue" "assessment" {
  name                = "assessment-queue"
  namespace_id        = azurerm_servicebus_namespace.this.id
  enable_partitioning = false
}

resource "azurerm_servicebus_namespace_authorization_rule" "this" {
  name         = "${local.deprecated_prefix}-sb-ns-auth-rule"
  namespace_id = azurerm_servicebus_namespace.this.id
  listen       = true
  send         = true
  manage       = true
}

resource "azurerm_servicebus_queue_authorization_rule" "assessment_oasiscodingstation" {
  name     = "${local.deprecated_prefix}-sbq-asmt-ocs-auth-rule"
  queue_id = azurerm_servicebus_queue.assessment.id
  listen   = true
  send     = false
  manage   = false
}

resource "azurerm_servicebus_queue_authorization_rule" "assessment_bt" {
  name     = "${local.deprecated_prefix}-sbq-asmt-bt-auth-rule"
  queue_id = azurerm_servicebus_queue.assessment.id
  listen   = false
  send     = true
  manage   = false
}

resource "azurerm_servicebus_queue_authorization_rule" "assessment_healthcarefirst" {
  name     = "${local.deprecated_prefix}-sbq-asmt-hc1-auth-rule"
  queue_id = azurerm_servicebus_queue.assessment.id
  listen   = false
  send     = true
  manage   = false
}

resource "azurerm_servicebus_queue" "firstintel" {
  name                = "firstintel-assessment-queue"
  namespace_id        = azurerm_servicebus_namespace.this.id
  enable_partitioning = false
}

resource "azurerm_servicebus_queue_authorization_rule" "firstintel_oasiscodingstation" {
  name     = "${local.deprecated_prefix}-sbq-firstintel-ocs-auth-rule"
  queue_id = azurerm_servicebus_queue.firstintel.id
  listen   = false
  send     = true
  manage   = false
}

resource "azurerm_servicebus_queue_authorization_rule" "firstintel_healthcarefirst" {
  name     = "${local.deprecated_prefix}-sbq-firstintel-hc1-auth-rule"
  queue_id = azurerm_servicebus_queue.firstintel.id
  listen   = true
  send     = false
  manage   = false
}

resource "azurerm_servicebus_queue" "assessment_review" {
  name                = "assessment-review-queue"
  namespace_id        = azurerm_servicebus_namespace.this.id
  enable_partitioning = false
}

resource "azurerm_servicebus_queue_authorization_rule" "assessment_review_oasiscodingstation" {
  name     = "${local.deprecated_prefix}-sbq-assessmentreview-ocs-auth-rule"
  queue_id = azurerm_servicebus_queue.assessment_review.id
  listen   = true
  send     = true
  manage   = false
}

resource "azurerm_servicebus_queue" "codingevent" {
  name                = "codingevent-queue"
  namespace_id        = azurerm_servicebus_namespace.this.id
  enable_partitioning = false
}

resource "azurerm_servicebus_queue_authorization_rule" "codingevent_bt" {
  name     = "${local.deprecated_prefix}-sbq-codingevent-bt-auth-rule"
  queue_id = azurerm_servicebus_queue.codingevent.id
  listen   = false
  send     = true
  manage   = false
}

resource "azurerm_servicebus_queue_authorization_rule" "codingevent_cp" {
  name     = "${local.deprecated_prefix}-sbq-codingevent-cp-auth-rule"
  queue_id = azurerm_servicebus_queue.codingevent.id
  listen   = true
  send     = false
  manage   = false
}

resource "azurerm_servicebus_topic" "recommendations" {
  name                = "assessment-recommendations-completed"
  namespace_id        = azurerm_servicebus_namespace.this.id
  enable_partitioning = true
}

resource "azurerm_servicebus_topic_authorization_rule" "recommendations_oasiscodingstation" {
  name     = "${local.deprecated_prefix}-sbt-rec-ocs-auth-rule"
  topic_id = azurerm_servicebus_topic.recommendations.id
  listen   = false
  send     = true
  manage   = false
}

resource "azurerm_servicebus_topic_authorization_rule" "recommendations_bt" {
  name     = "${local.deprecated_prefix}-sbt-rec-bt-auth-rule"
  topic_id = azurerm_servicebus_topic.recommendations.id
  listen   = true
  send     = false
  manage   = false
}

resource "azurerm_servicebus_subscription" "afo" {
  for_each = var.production_environments

  name                      = each.value
  topic_id                  = azurerm_servicebus_topic.recommendations.id
  max_delivery_count        = 10
  lock_duration             = "PT5M"
  enable_batched_operations = true
}

resource "azurerm_servicebus_subscription_rule" "afo" {
  for_each = var.production_environments

  name            = format("%s-CorrelationRule", each.value)
  subscription_id = azurerm_servicebus_subscription.afo[each.value].id
  filter_type     = "CorrelationFilter"

  correlation_filter {
    correlation_id = each.value
  }
}

resource "azurerm_servicebus_topic" "healthcarefirst" {
  name                = "assessment-healthcarefirst-completed"
  namespace_id        = azurerm_servicebus_namespace.this.id
  enable_partitioning = true
}

resource "azurerm_servicebus_topic_authorization_rule" "healthcarefirst_oasiscodingstation" {
  name     = "${local.deprecated_prefix}-sbt-healthcarefirst-ocs-auth-rule"
  topic_id = azurerm_servicebus_topic.healthcarefirst.id
  listen   = false
  send     = true
  manage   = false
}

resource "azurerm_servicebus_topic_authorization_rule" "healthcarefirst_healthcarefirst" {
  name     = "${local.deprecated_prefix}-sbt-healthcarefirst-hc1-auth-rule"
  topic_id = azurerm_servicebus_topic.healthcarefirst.id
  listen   = true
  send     = false
  manage   = false
}

resource "azurerm_servicebus_subscription" "healthcarefirst" {
  name               = "HealthcareFirst"
  topic_id           = azurerm_servicebus_topic.healthcarefirst.id
  max_delivery_count = 10
}

resource "azurerm_servicebus_subscription_rule" "healthcarefirst" {
  name            = "CorrelationRule"
  subscription_id = azurerm_servicebus_subscription.healthcarefirst.id
  filter_type     = "CorrelationFilter"

  correlation_filter {
    correlation_id = "HealthcareFirst"
  }
}
