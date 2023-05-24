output "servicebus_queue_name" {
  description = "Name of the Service Bus Queue used for Coding Services Events."
  value       = azurerm_servicebus_queue.codingevent.name
}

output "servicebus_queue_auth_rule_name" {
  description = "Name of the Authorization Rule for a ServiceBus Queue used for Coding Services Events."
  value       = azurerm_servicebus_queue_authorization_rule.codingevent_cp.name
}
