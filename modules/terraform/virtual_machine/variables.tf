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

variable "virtual_machine_suffix" {
  description = "Suffix used for virtual machine name."
  default     = ["-error"]
  type        = list(string)
}

variable "enable_availability_set" {
  description = "Whether to deploy or use existing availability set."
  default     = true
}

variable "availability_set_id" {
  description = "ID of the existing availability set which machines should be added to."
  default     = null
  type        = string
}

variable "availability_set_suffix" {
  description = "Suffix used for availability set name in case it should be deployed."
  default     = ""
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
  description = "Suffix used for boot diagnostics storage account name. If specified will be concatenated with resource_prefix variable to get the final storage account name which will be created and used for VM diagnostic data. "
  default     = ""
}

variable "loadbalancer_suffix" {
  description = "Suffix used for the name of the load balancer."
  default     = "-ilb"
}

variable "network_interface_suffix" {
  description = "Suffix used for network interface name."
  default     = "-nic"
}

variable "os_disk_suffix" {
  description = "Suffix used for OS disk name."
  default     = "-osdisk"
}

variable "data_disk_suffix" {
  description = "Suffix used for data disk name."
  default     = "-datadisk"
}

variable "subnet_resource" {
  description = "Partial Subnet resource with two keys for ID of the subnet VMs should be connected to and address prefix used by the subnet."
  default     = null
  type        = object({ id = string, address_prefixes = list(string) })
}

variable "quantity" {
  description = "Number of the virtual machines to create."
  default     = null
  type        = number
}

variable "vm_starting_number" {
  description = "Number which should be used for the first virtual machine. Incremented by 1 afterwards if the count is greater than 1."
  default     = 1
}

variable "dns_servers" {
  description = "List of the DNS servers which should be applied for the virtual machine."
  default     = []
  type        = list(string)
}

variable "vm_starting_ip" {
  description = "Last octet of the IP address which should be allocated for the first virtual machine. Incremented by 1 afterwards if the count is greater than 1."
  default     = null
  type        = number
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

variable "data_disk" {
  description = "List of additional data disks with properties: name of the disk (should be unique in the list), storage type, size in gigabytes and lun number. If the image plan variables are specified this variable will be ignored."
  default     = []
  type        = list(object({ name = string, type = string, size = number, lun = number, caching = string }))
}

variable "disk_size_gb" {
  description = "VM OS Disk Space"
  type        = string
  default     = "127"
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

variable "vm_size" {
  description = "Size of the Virtual Machine." # https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes
  default     = "Standard_A2_v2"
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

variable "license_type" {
  description = "Specifies the type of on-premise license (Azure Hybrid Use Benefit) which should be used. Possible values are 'None', 'Windows_Client' and 'Windows_Server'."
  default     = null
  type        = string
}

variable "priority" {
  description = "Specifies the priority of this Virtual Machine. Possible values are: 'Regular' and 'Spot'."
  default     = "Regular"
}

variable "max_bid_price" {
  description = "The maximum price to pay for Virtual Machine, in US Dollars; which must be greater than the current spot price. If this bid price falls below the current spot price the Virtual Machine will be evicted using the eviction_policy."
  default     = "-1"
}

variable "eviction_policy" {
  description = "Specifies what should happen when the Virtual Machine is evicted for price reasons when using a Spot instance."
  default     = "Deallocate"
}

variable "allow_extension_operations" {
  description = "Should Extension Operations be allowed or not."
  default     = true
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

variable "admin_username" {
  description = "Name of the local administrator account."
  default     = "b3admin"
}

variable "admin_password" {
  description = "Password of the local administrator account."
  default     = null
  type        = string
}

variable "patch_mode" {
  description = "Specifies the mode of in-guest patching to this Windows Virtual Machine. Possible values are 'Manual', 'AutomaticByOS' or 'AutomaticByPlatform'."
  default     = "Manual"
}

variable "timezone" {
  description = "Time zone which should be used by the windows virtual machine, activated only during creation of it. Valid values can be spot on https://docs.microsoft.com/en-us/azure/azure-sql/managed-instance/timezones-overview#list-of-supported-time-zones"
  default     = null
  type        = string
}

variable "ssh_keys" {
  description = "List of ssh public keys which should be trusted for specified admin username."
  default     = []
  type        = list(string)
}

variable "create_system_assigned_identity" {
  description = "Whether to create a 'SystemAssigned' identity which should be used for the virtual machine or not."
  default     = false
}

variable "tags" {
  description = "Tags to organize Azure resources."
  default     = {}
  type        = map(string)
}

variable "user_assigned_identity_ids" {
  description = "Specifies a list of user managed identity ids to be assigned."
  default     = []
  type        = list(string)
}

variable "module_depends_on" {
  description = "Names of resources this module should depend upon."
  default     = null
  type        = any
}
