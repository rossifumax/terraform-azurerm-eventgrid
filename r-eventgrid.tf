resource "azurerm_eventgrid_system_topic" "eventgrid_system_topic" {
  name                = local.eventgrid_name
  resource_group_name = var.resource_group_name
  location            = var.location

  source_arm_resource_id = var.source_resource_id
  topic_type             = local.topic_type

  identity {
    type = "SystemAssigned"
  }

  tags = merge(local.default_tags, var.extra_tags)
}

module "event_subscription" {
  source = "./modules/event-subscription"

  resource_group_name = var.resource_group_name
  location_short      = var.location_short
  stack               = var.stack
  environment         = var.environment
  client_name         = var.client_name

  eventgrid_system_topic_id      = azurerm_eventgrid_system_topic.eventgrid_system_topic.id
  event_subscription_custom_name = var.event_subscription_custom_name

  expiration_time_utc   = var.expiration_time_utc
  event_delivery_schema = var.event_delivery_schema

  azure_function_endpoint       = var.azure_function_endpoint
  eventhub_endpoint_id          = var.eventhub_endpoint_id
  hybrid_connection_endpoint_id = var.hybrid_connection_endpoint_id
  service_bus_queue_endpoint_id = var.service_bus_queue_endpoint_id
  service_bus_topic_endpoint_id = var.service_bus_topic_endpoint_id
  storage_queue_endpoint        = var.storage_queue_endpoint
  webhook_endpoint              = var.webhook_endpoint

  included_event_types = var.included_event_types

  subject_filter  = var.subject_filter
  advanced_filter = var.advanced_filter

  storage_blob_dead_letter_destination = var.storage_blob_dead_letter_destination
  retry_policy                         = var.retry_policy
  labels                               = var.labels
  advanced_filtering_on_arrays_enabled = var.advanced_filtering_on_arrays_enabled
}
