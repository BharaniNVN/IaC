variable "resource_group_resource" {
  description = "Partial resource group resource with keys for its name and location."
  default     = { name = "", location = "" }
  type        = object({ name = string, location = string })
}

variable "location" {
  description = "Azure region where resources will be deployed."
  default     = ""
}

variable "resource_prefix" {
  description = "Prefix which will be used in the name of every created resource."
  default     = ""
}

variable "vmss_suffix" {
  description = "Suffix used for virtual machine scale set name."
  default     = ["-error"]
  type        = list(string)
}

variable "quantity" {
  description = "Number of the virtual machines scale sets to create."
  default     = null
  type        = number
}

variable "enable_boot_diagnostics_storage_account" {
  description = "Whether to deploy or use existing storage account for boot diagnostic."
  default     = true
}

variable "boot_diagnostics_storage_blob_endpoint" {
  description = "Existing storage URI for storing VMs boot diagnostics data."
  default     = null
  type        = string
}

variable "boot_diagnostics_storage_account_suffix" {
  description = "Suffix used for boot diagnostics storage account name. If specified will be concatenated with resource_prefix variable to get the final storage account name which will be created and used for VMSS diagnostic data. "
  default     = ""
}

variable "loadbalancer_suffix" {
  description = "Suffix used for the name of the load balancer."
  default     = "-ilb"
}

variable "subnet_resource" {
  description = "Partial Subnet resource with two keys for ID of the subnet VMSSs should be connected to and address prefix used by the subnet."
  default     = null
  type        = object({ id = string, address_prefixes = list(string) })
}

variable "enable_internal_loadbalancer" {
  description = "Whether to deploy or not internal Azure Load balancer."
  default     = false
}

variable "lb_sku" {
  description = "SKU of the Azure Load Balancer. Valid values are: 'Basic' and 'Standard'."
  default     = "Basic"
}

variable "lb_ip" {
  description = "Last octet of the IP address for internal load balancer."
  default     = null
  type        = number
}

variable "lb_enable_ha_ports" {
  description = "Whether to enable HA Ports mode for load balancer. Used only with Standard Load Balancer SKU, at least one element in lb_rules should be defined with probe value."
  default     = false
}

variable "lb_rules" {
  description = "Load-balancing rules in the form of the list of maps with two keys: 'probe' and 'rule' - both of those should be defined as a map with key name equal to protocol and value equal to port number. In case of Standard Load Balancer SKU and enabled HA ports feature, the first element in a list will be used for probe port."
  default     = []
  type        = list(object({ probe = map(number), rule = map(number) }))
}

variable "lb_load_distribution" {
  description = "Specifies which parameters should be included in determining whether a client should be handled by the same virtual machine in the backend pool. Valid values are: 'Default', 'SourceIP', 'SourceIPProtocol'."
  default     = "Default"
}

variable "enable_lb_backend_address_pool_association" {
  description = "Whether to associate network interfaces with backend pool or not."
  default     = false
}

variable "lb_backend_address_pool_id" {
  description = "ID of the existing load balancer backend pool. If provided new backend address pool won't be created and this pool will be used to associate network interfaces with itself."
  default     = null
  type        = string
}

variable "plan_name" {
  description = "Name of the image from the marketplace."
  default     = ""
}

variable "plan_publisher" {
  description = "Publisher of the image."
  default     = ""
}

variable "plan_product" {
  description = "Product of the image from the marketplace."
  default     = ""
}

variable "admin_username" {
  description = "Name of the local administrator account."
  default     = "mxadmin"
}

variable "admin_password" {
  description = "Password of the local administrator account."
  default     = null
  type        = string
}

variable "computer_name_prefix" {
  description = "The prefix which should be used for the name of the virtual machines in this scale set. If unspecified this defaults to the value for the name field."
  default     = null
  type        = string
}

variable "enable_automatic_updates" {
  description = "Whether automatic updates enabled for virtual machine instances or not."
  default     = true
}

variable "eviction_policy" {
  description = "Specifies what should happen when the Virtual Machine is evicted for price reasons when using a Spot instance. Possible values are 'Deallocate' or 'Delete'."
  default     = "Delete"
}

variable "instances" {
  description = "The number of virtual machines in the scale set."
  default     = 2
}

variable "license_type" {
  description = "Specifies the type of on-premise license (Azure Hybrid Use Benefit) which should be used. Possible values are 'None', 'Windows_Client' and 'Windows_Server'."
  default     = "None"
  type        = string
}

variable "max_bid_price" {
  description = "The maximum price to pay for Virtual Machine, in US Dollars; which must be greater than the current spot price. If this bid price falls below the current spot price the Virtual Machine will be evicted using the eviction_policy."
  default     = "-1"
}

variable "overprovision" {
  description = "Whether Azure will over-provision virtual machines in the scale set or not."
  default     = true
}

variable "platform_fault_domain_count" {
  description = "Specifies the number of fault domains that are used by this virtual machine scale set."
  default     = null
  type        = number
}

variable "priority" {
  description = "Specifies the priority of this Virtual Machine. Possible values are: 'Regular' and 'Spot'."
  default     = "Regular"
}

variable "scale_in_policy" {
  description = "The scale-in policy rule that decides which virtual machines are chosen for removal when a virtual machine scale set is scaled in. Possible values for the scale-in policy rules are 'Default', 'NewestVM' and 'OldestVM'."
  default     = "Default"
}

variable "single_placement_group" {
  description = "Should this virtual machine scale set be limited to a single placement group, which means the number of instances will be capped at 100 virtual machines."
  default     = true
}

variable "timezone" {
  description = "Time zone which should be used by the windows virtual machine, activated only during creation of it. Valid values can be spot on https://docs.microsoft.com/en-us/azure/azure-sql/managed-instance/timezones-overview#list-of-supported-time-zones"
  default     = null
  type        = string
}

variable "upgrade_mode" {
  description = "Specifies how upgrades (e.g. changing the image/SKU) should be performed to virtual machine instances. Possible values are 'Automatic', 'Manual' and 'Rolling'."
  default     = "Manual"
}

variable "vmss_size" {
  description = "Size of the Virtual Machine Scale Set." # https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes
  default     = "Standard_DS2_v2"
}

variable "ssh_keys" {
  description = "List of ssh public keys which should be trusted for specified admin username."
  default     = []
  type        = list(string)
}

variable "data_disk" {
  description = "List of additional data disks with properties: storage type, size in gigabytes, lun number and caching option. If the image plan variables are specified this variable will be ignored."
  default     = []
  type        = list(object({ type = string, size = number, lun = number, caching = string }))
}

variable "extension" {
  description = "List of extensions with properties: name, publisher, type and type_handler_version option. Optionally protected_settings, provision_after_extensions and settings could be specified."
  default     = []
  type        = list(object({ name = string, publisher = string, type = string, type_handler_version = string, protected_settings = string, provision_after_extensions = list(string), settings = string }))
}

variable "extensions_time_budget" {
  description = "Specifies the duration allocated for all extensions to start."
  default     = "PT1H"
}

variable "network_interface_suffix" {
  description = "Suffix used for network interface name."
  default     = "-nic"
}

variable "dns_servers" {
  description = "List of the DNS servers which should be applied for the virtual machine scale sets."
  default     = []
  type        = list(string)
}

variable "enable_accelerated_networking" {
  description = "Whether to enable accelerated networking on the network interface or not."
  default     = false
}

variable "enable_ip_forwarding" {
  description = "Whether to enable ip forwarding on the network interface or not."
  default     = false
}

variable "os_type" {
  description = "Whether OS is Windows or Linux. Could be automatically fetched from image_offer value."
  default     = null
  type        = string
}

variable "os_managed_disk_type" {
  description = "Type of managed disk to create for the OS."
  default     = "StandardSSD_LRS"
}

variable "os_disk_size_gb" {
  description = "The Size of the internal OS disk in GB."
  default     = null
  type        = number
}

variable "os_disk_caching" {
  description = "The type of caching which should be used for the internal OS disk. Possible values are 'None', 'ReadOnly' and 'ReadWrite'."
  default     = "ReadWrite"
}

variable "enable_ephemeral_os_disk" {
  description = "Whether enable ephemeral disk support for the OS disk or not.."
  default     = false
}

variable "max_batch_instance_percent" {
  description = "The maximum percent of total virtual machine instances that will be upgraded simultaneously by the rolling upgrade in one batch."
  default     = 20
}

variable "max_unhealthy_instance_percent" {
  description = "The maximum percentage of the total virtual machine instances in the scale set that can be simultaneously unhealthy, either as a result of being upgraded, or by being found in an unhealthy state by the virtual machine health checks before the rolling upgrade aborts."
  default     = 20
}

variable "max_unhealthy_upgraded_instance_percent" {
  description = "The maximum percentage of upgraded virtual machine instances that can be found to be in an unhealthy state."
  default     = 20
}

variable "pause_time_between_batches" {
  description = "The wait time between completing the update for all virtual machines in one batch and starting the next batch. The time duration should be specified in ISO 8601 format."
  default     = "PT0S"
}

variable "keyvault_id" {
  description = "Resource ID of the Azure Key Vault."
  default     = null
  type        = string
}

variable "certificate_urls" {
  description = "The IDs of the associated Key Vault Certificates."
  default     = []
  type        = list(string)
}

variable "certificate_store_name" {
  description = "Certificate store name."
  default     = "My"
}

variable "image_publisher" {
  description = "Publisher of the image used to create the virtual machine."
  default     = "MicrosoftWindowsServer"
}

variable "image_offer" {
  description = "Offer of the image used to create the virtual machine"
  default     = "WindowsServer"
}

variable "image_sku" {
  description = "SKU of the image used to create the virtual machine."
  default     = "2019-Datacenter"
}

variable "image_version" {
  description = "Version of the image used to create the virtual machine."
  default     = "latest"
}

variable "enable_terminate_notification" {
  description = "Whether to enable terminate notification on virtual machine scale set or not."
  default     = false
}

variable "terminate_notification_timeout" {
  description = "Length of time (in minutes, between 5 and 15) a notification to be sent to the VM on the instance metadata server till the VM gets deleted. The time duration should be specified in ISO 8601 format."
  default     = null
  type        = string
}

variable "tags" {
  description = "Tags to organize Azure resources."
  default     = {}
  type        = map(string)
}

variable "module_depends_on" {
  description = "Names of resources this module should depend upon."
  default     = null
  type        = any
}
