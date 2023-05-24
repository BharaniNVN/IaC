variable "resource_group_name" {
  description = "Name of the resource group to deploy to."
}

variable "location" {
  description = "Azure region where resources will be deployed."
  default     = ""
}

variable "resource_prefix" {
  description = "Prefix which will be used in the name of every created resource."
  default     = ""
}

variable "public_ip_domain_suffix" {
  description = "Suffix used for the domain label name of the public IP."
  default     = "-mxhhp-agw"
}

variable "backend_address_pool_suffix" {
  description = "Suffix used for backend address pool name."
  default     = "-beap"
}

variable "http_listener_suffix" {
  description = "Suffix used for the name of http listener."
  default     = "-lsnr"
}

variable "request_routing_rule_suffix" {
  description = "Suffix used for the name of request routing rule."
  default     = "-rule"
}

variable "backend_http_settings_suffix" {
  description = "Suffix used for the name of backend http settings."
  default     = "-https-settings"
}

variable "probe_suffix" {
  description = "Suffix used for the name of probe."
  default     = "-probe"
}

variable "agw_sku" {
  description = "Name of the SKU. Possible values: Standard_Small, Standard_Medium, Standard_Large, WAF_Medium, WAF_Large, and WAF_v2"
  default     = "WAF_v2"
}

variable "agw_tier" {
  description = "Could be set to either 'Standard'/'Standard_v2' (=simple AGW, no WAF) or 'WAF'/'WAF_v2' (=AGW with WAF functional)"
  default     = "WAF_v2"
}

variable "agw_capacity" {
  description = " The Capacity of the SKU to use for this Application Gateway - which must be between 1 and 10"
  default     = 2
}

variable "waf_mode" {
  description = "Could be set to either 'Detection' or 'Prevention'"
  default     = "Detection"
}

variable "subnet_resource" {
  description = "Partial subnet resource which the Application Gateway should be connected to."
  default     = null
  type        = object({ id = string, address_prefixes = list(string) })
}

variable "certificates" {
  description = "A list of certificate name, its secret id in key vault and key vault id itself."
  default     = []
  type        = list(object({ name = string, key_vault_id = string, key_vault_secret_id = string }))
}

variable "cookie_based_affinity" {
  description = "Is Cookie-Based Affinity enabled for Backend HTTP settings? Possible values are Enabled and Disabled"
  default     = "Disabled"
  type        = string
}

variable "connection_draining_timeout" {
  description = "The number of seconds connection draining is active. Acceptable values are from 1 second to 3600 seconds."
  default     = 300
}

variable "agw_probe_interval" {
  description = "The Interval between two consecutive probes in seconds. Possible values range from 1 second to a maximum of 86,400 seconds."
  default     = 90
}

variable "agw_probe_timeout" {
  description = "The Timeout used for this Probe, which indicates when a probe becomes unhealthy. Possible values range from 1 second to a maximum of 86,400 seconds"
  default     = 30
}

variable "agw_probe_unhealthy_threshold" {
  description = "Indicates the amount of retries which should be attempted before a node is deemed unhealthy. Possible values are 1 - 20 seconds"
  default     = 3
}

variable "agw_probe_match_statuscodes" {
  description = "A list of allowed status codes"
  default     = ["200"]
}

variable "mappings" {
  description = "Mappings of hostnames with backend pools and probe settings (if needed)"
  default     = {}
}

variable "tags" {
  description = "Tags to organize Azure resources."
  default     = {}
  type        = map(string)
}

variable "log_analytics_id" {
  description = "The resource ID for the Log Analytics."
  default     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/dummy-RG/providers/microsoft.operationalinsights/workspaces/theOne"
}

variable "eventhub_policy" {
  description = "Partial Event Hub policy resource used for AlienVault"
  default     = null
  type        = object({ id = string, name = string })
}

variable "eventhub_name" {
  description = "Event Hub name. Should contain a value if the eventhub namespace contains multiple eventhubs"
  default     = ""
}

variable "agw_private_ip_index" {
  description = "IP address for private AGW frontend"
  default     = null
  type        = number
}

variable "fe_configs" {
  description = "A list of front-end configurations. Could be public, private or public/private"
  default     = []
  type        = list(string)
}

variable "agw_listens_on" {
  description = "Defines name of the front-end configuration for binding listeners. Could be private or public"
  default     = "private"
}

variable "agw_http_request_timeout" {
  description = "Defines timeout for application gateway HTTP settings"
  default     = 10
}

variable "module_depends_on" {
  description = "Names of resources this module should depend upon."
  default     = null
  type        = any
}