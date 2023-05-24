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

variable "availability_set_suffix" {
  description = "Suffix used for availability set name."
  default     = ""
}

variable "boot_diagnostics_storage_blob_endpoint" {
  description = "Existing storage URI for storing VMs boot diagnostics data. Takes precedence over boot_diagnostics_storage_account_suffix variable."
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

variable "os_managed_disk_type" {
  description = "Type of managed disk to create for the OS."
  default     = "Standard_LRS"
}

variable "data_disk" {
  description = "List of additional data disks with properties: name of the disk (should be unique in the list), storage type, size in gigabytes, lun number and caching option (None, ReadOnly or ReadWrite). If the image plan variables are specified this variable will be ignored."
  default     = []
  type        = list(object({ name = string, type = string, size = number, lun = number, caching = string }))
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

variable "vm_size" {
  description = "Size of the Virtual Machine." # https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes
  default     = "Standard_A2_v2"
}

variable "plan_name" {
  description = "Name of the image from the marketplace."
  default     = "unified-security-management-anywhere"
}

variable "plan_publisher" {
  description = "Publisher of the image."
  default     = "alienvault"
}

variable "plan_product" {
  description = "Product of the image from the marketplace."
  default     = "unified-security-management-anywhere"
}

variable "image_publisher" {
  description = "Publisher of the image used to create the virtual machine."
  default     = "alienvault"
}

variable "image_offer" {
  description = "Offer of the image used to create the virtual machine"
  default     = "unified-security-management-anywhere"
}

variable "image_sku" {
  description = "SKU of the image used to create the virtual machine."
  default     = "unified-security-management-anywhere"
}

variable "image_version" {
  description = "Version of the image used to create the virtual machine."
  default     = "6.0.188"
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

variable "create_system_assigned_identity" {
  description = "Whether to create a 'SystemAssigned' identity which should be used for the virtual machine or not."
  default     = false
  type        = bool
}

variable "user_assigned_identity_ids" {
  description = "Specifies a list of user managed identity ids to be assigned."
  default     = []
  type        = list(string)
}

variable "ssh_keys" {
  description = "List of ssh public keys which should be trusted for specified admin username."
  default     = []
  type        = list(string)
}

variable "tags" {
  description = "Tags to organize Azure resources."
  default     = {}
  type        = map(string)
}

variable "log_analytics_extension_version" {
  description = "Version of the Azure Log Analytics Agent extension to use for different OS."
  default     = { "windows" = "1.0", "linux" = "1.11" }
  type        = object({ windows = string, linux = string })
}

variable "log_analytics_workspace_resource" {
  description = "Partial Log Analytics Workspace resource with two keys for Workspace (or Customer) ID and Primary (or Secondary) shared key."
  default     = null
  type        = object({ workspace_id = string, primary_shared_key = string })
}

variable "azure_firewall_resource" {
  description = "Azure Firewall resource on which outbound ports to be opened for proper AlienVault' Sensor communication with central server"
  default     = null
  type        = object({ name = string, resource_group_name = string })
}

variable "alienvault_outbount_ports" {
  description = "Map of the outboud protocols/ports needed to proper AlienVault' Sensor communication with central server"
  default = {
    "TCP" = ["7100", "22", "443", "5671", "5672"]
    "UDP" = ["123"]
  }
}

variable "azure_firewall_network_rule_collection_priority" {
  description = "Priority of network_rule_collection. Possible values are between 100 - 65000."
  default     = 3000
  type        = number
}

variable "module_depends_on" {
  description = "Names of resources this module should depend upon."
  default     = null
  type        = any
}
