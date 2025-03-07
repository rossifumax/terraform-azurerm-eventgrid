# Azure Event Grid - Topic event Subscription

This Terraform submodule creates an [Azure Eventgrid system topic event subscription](https://docs.microsoft.com/en-us/azure/event-grid/) service.

<!-- BEGIN_TF_DOCS -->
## Global versioning rule for Claranet Azure modules

| Module version | Terraform version | AzureRM version |
| -------------- | ----------------- | --------------- |
| >= 7.x.x       | 1.3.x             | >= 3.0          |
| >= 6.x.x       | 1.x               | >= 3.0          |
| >= 5.x.x       | 0.15.x            | >= 2.0          |
| >= 4.x.x       | 0.13.x / 0.14.x   | >= 2.0          |
| >= 3.x.x       | 0.12.x            | >= 2.0          |
| >= 2.x.x       | 0.12.x            | < 2.0           |
| <  2.x.x       | 0.11.x            | < 2.0           |

## Contributing

If you want to contribute to this repository, feel free to use our [pre-commit](https://pre-commit.com/) git hook configuration
which will help you automatically update and format some files for you by enforcing our Terraform code module best-practices.

More details are available in the [CONTRIBUTING.md](../../CONTRIBUTING.md#pull-request-process) file.

## Usage

This module is optimized to work with the [Claranet terraform-wrapper](https://github.com/claranet/terraform-wrapper) tool
which set some terraform variables in the environment needed by this module.
More details about variables set by the `terraform-wrapper` available in the [documentation](https://github.com/claranet/terraform-wrapper#environment).

```hcl
module "region" {
  source  = "claranet/regions/azurerm"
  version = "x.x.x"

  azure_region = var.azure_region
}

module "rg" {
  source  = "claranet/rg/azurerm"
  version = "x.x.x"

  location    = module.region.location
  client_name = var.client_name
  environment = var.environment
  stack       = var.stack
}

module "logs" {
  source  = "claranet/run/azurerm//modules/logs"
  version = "x.x.x"

  resource_group_name = module.rg.resource_group_name
  stack               = var.stack
  environment         = var.environment
  client_name         = var.client_name
  location            = module.region.location
  location_short      = module.region.location_short
}


data "azurerm_client_config" "current" {
}

module "keyvault" {
  source  = "claranet/keyvault/azurerm"
  version = "x.x.x"

  resource_group_name = module.rg.resource_group_name
  stack               = var.stack
  environment         = var.environment
  client_name         = var.client_name
  location            = module.region.location
  location_short      = module.region.location_short

  logs_destinations_ids = [
    module.logs.logs_storage_account_id,
    module.logs.log_analytics_workspace_id,
  ]

  admin_objects_ids = [
    data.azurerm_client_config.current.object_id
  ]
}


resource "azurerm_storage_account" "storage_acount" {
  name                     = "examplestorageacc"
  resource_group_name      = module.rg.resource_group_name
  location                 = module.region.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  queue_properties {
    logging {
      delete                = true
      read                  = true
      write                 = true
      version               = "1.0"
      retention_policy_days = 10
    }
  }
}

resource "azurerm_storage_queue" "storage_queue" {
  name                 = "mysamplequeue"
  storage_account_name = azurerm_storage_account.storage_acount.name
}

module "eventgrid" {
  source  = "claranet/eventgrid/azurerm"
  version = "x.x.x"

  resource_group_name = module.rg.resource_group_name
  stack               = var.stack
  environment         = var.environment
  client_name         = var.client_name
  location            = module.region.location
  location_short      = module.region.location_short

  source_resource_id = module.keyvault.key_vault_id

  storage_queue_endpoint = {
    storage_account_id = azurerm_storage_account.storage_acount.id
    queue_name         = azurerm_storage_queue.storage_queue.name
  }

  logs_destinations_ids = [
    module.logs.logs_storage_account_id,
    module.logs.log_analytics_workspace_id
  ]
}

module "additional_event_subscription" {
  source  = "claranet/eventgrid/azurerm//modules/event-subscription"
  version = "x.x.x"

  resource_group_name = module.rg.resource_group_name
  stack               = var.stack
  environment         = var.environment
  client_name         = var.client_name
  location_short      = module.region.location_short

  eventgrid_system_topic_id = module.eventgrid.id

  included_event_types = ["Microsoft.KeyVault.CertificateNewVersionCreated"]

  storage_queue_endpoint = {
    storage_account_id = azurerm_storage_account.storage_acount.id
    queue_name         = azurerm_storage_queue.storage_queue.name
  }
}
```

## Providers

| Name | Version |
|------|---------|
| azurecaf | ~> 1.1 |
| azurerm | ~> 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_eventgrid_system_topic_event_subscription.event_subscription](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventgrid_system_topic_event_subscription) | resource |
| [azurecaf_name.eventgrid_event_sub](https://registry.terraform.io/providers/aztfmod/azurecaf/latest/docs/data-sources/name) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| advanced\_filter | Filter a value of an event for an event subscription based on a condition | `any` | `{}` | no |
| advanced\_filtering\_on\_arrays\_enabled | Specifies whether advanced filters should be evaluated against an array of values instead of expecting a singular value | `bool` | `false` | no |
| azure\_function\_endpoint | Function where the Event Subscription will receive events | `any` | `{}` | no |
| client\_name | Client name/account used in naming | `string` | n/a | yes |
| environment | Project environment | `string` | n/a | yes |
| event\_delivery\_schema | Specifies the event delivery schema for the event subscription. Possible values include: `EventGridSchema`, `CloudEventSchemaV1_0`, `CustomInputSchema`. | `string` | `"EventGridSchema"` | no |
| event\_subscription\_custom\_name | Event subscription optional custom name | `string` | `""` | no |
| eventgrid\_system\_topic\_id | Eventgrid system topic ID to attach the event subscription | `string` | n/a | yes |
| eventhub\_endpoint\_id | ID of the EventHub where the Event subscription will receive events | `string` | `null` | no |
| expiration\_time\_utc | Specifies the expiration time of the event subscription (Datetime Format RFC 3339). | `string` | `null` | no |
| hybrid\_connection\_endpoint\_id | ID of the Hybrid Connection where the Event subscription will receive events | `string` | `null` | no |
| included\_event\_types | List of applicable event types that need to be part of the event subscription | `list(string)` | `[]` | no |
| labels | List of labels to assign to the event subscription | `list(string)` | `null` | no |
| location\_short | Short string for Azure location. | `string` | n/a | yes |
| name\_prefix | Optional prefix for the generated name | `string` | `""` | no |
| name\_suffix | Optional suffix for the generated name | `string` | `""` | no |
| resource\_group\_name | Resource group name | `string` | n/a | yes |
| retry\_policy | Delivery retry attempts for events | `any` | `{}` | no |
| service\_bus\_queue\_endpoint\_id | ID of the Service Bus Queue where the Event subscription will receive events | `string` | `null` | no |
| service\_bus\_topic\_endpoint\_id | ID of the Service Bus Topic where the Event subscription will receive events | `string` | `null` | no |
| stack | Project stack name | `string` | n/a | yes |
| storage\_blob\_dead\_letter\_destination | Storage blob container that is the destination of the deadletter events | `any` | `{}` | no |
| storage\_queue\_endpoint | Storage Queue endpoint block configuration where the Event subscription will receive events | `any` | `{}` | no |
| subject\_filter | Block to filter events for an event subscription based on a resource path prefix or sufix | `any` | `{}` | no |
| use\_caf\_naming | Use the Azure CAF naming provider to generate default resource name. `custom_name` override this if set. Legacy default name is used if this is set to `false`. | `bool` | `true` | no |
| webhook\_endpoint | Webhook configuration block where the Event Subscription will receive events. | <pre>object({<br>    url                               = optional(string, "")<br>    base_url                          = optional(string)<br>    max_events_per_batch              = optional(number)<br>    preferred_batch_size_in_kilobytes = optional(number)<br>    active_directory_tenant_id        = optional(string)<br>    active_directory_app_id_or_uri    = optional(string)<br>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Eventgrid subscription ID |
| name | Evengrid subscription name |
<!-- END_TF_DOCS -->
