variable "resource_group_resource" {
  description = "Partial resource group resource with keys for its name and location."
  default     = { name = "", location = "" }
  type        = object({ name = string, location = string })
}

variable "location" {
  description = "Azure region where resources will be deployed."
  default     = ""
}

variable "quantity" {
  description = "Number of the virtual machines to create."
  default     = null
  type        = number
}

variable "resource_prefix" {
  description = "Prefix which will be used in the name of every created resource."
  default     = ""
}

variable "availability_set_suffix" {
  description = "Suffix used for availability set name."
  default     = ""
}

variable "loadbalancer_suffix" {
  description = "Suffix used for the name of the load balancer."
  default     = "-ilb"
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

variable "boot_diagnostics_storage_account_suffix" {
  description = "Suffix used for boot diagnostics storage account name. If specified will be concatenated with resource_prefix variable to get the final storage account name which will be created and used for VM diagnostic data. "
  default     = ""
}

variable "boot_diagnostics_storage_blob_endpoint" {
  description = "Existing storage URI for storing VMs boot diagnostics data. Takes precedence over boot_diagnostics_storage_account_suffix variable."
  default     = null
  type        = string
}

variable "network_interface_suffix" {
  description = "Suffix used for network interface name."
  default     = "-nic"
}

variable "subnet_resource" {
  description = "Partial Subnet resource with two keys for ID of the subnet VMs should be connected to and address prefix used by the subnet."
  default     = null
  type        = object({ id = string, address_prefixes = list(string) })
}

variable "endpoint_subnet_resource" {
  description = "Partial Subnet resource with two keys (ID and address prefix) to place private endpoints."
  default     = null
  type        = object({ id = string, address_prefixes = list(string) })
}

variable "vm_starting_ip" {
  description = "Last octet of the IP address which should be allocated for the first virtual machine. Incremented by 1 afterwards if the count is greater than 1."
  default     = null
  type        = number
}

variable "dns_servers" {
  description = "List of the DNS servers which should be applied for the virtual machine."
  default     = []
  type        = list(string)
}

variable "data_disk_suffix" {
  description = "Suffix used for data disk name."
  default     = "-datadisk"
}

variable "data_disk" {
  description = "List of additional data disks with properties: name of the disk (should be unique in the list), storage type, size in gigabytes, lun number and caching option (None, ReadOnly or ReadWrite). If the image plan variables are specified this variable will be ignored."
  default     = []
  type        = list(object({ name = string, type = string, size = number, lun = number, caching = string }))
}

variable "virtual_machine_suffix" {
  description = "Suffix used for virtual machine name."
  default     = ["-error"]
  type        = list(string)
}

variable "vm_starting_number" {
  description = "Number which should be used for the first virtual machine. Incremented by 1 afterwards if the count is greater than 1."
  default     = 1
}

variable "vm_size" {
  description = "Size of the Virtual Machine." # https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes
  default     = "Standard_B2s"
}

variable "image_publisher" {
  description = "Publisher of the image used to create the virtual machine."
  default     = "RedHat"
}

variable "image_offer" {
  description = "Offer of the image used to create the virtual machine"
  default     = "RHEL"
}

variable "image_sku" {
  description = "SKU of the image used to create the virtual machine."
  default     = "8"
}

variable "image_version" {
  description = "Version of the image used to create the virtual machine."
  default     = "latest"
}

variable "os_disk_suffix" {
  description = "Suffix used for OS disk name."
  default     = "-osdisk"
}

variable "os_managed_disk_type" {
  description = "Type of managed disk to create for the OS."
  default     = "StandardSSD_LRS"
}

variable "admin_username" {
  description = "Name of the local administrator account."
  default     = "BtHHHAzureAdmin"
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

variable "tags" {
  description = "Tags to organize Azure resources."
  default     = {}
  type        = map(string)
}

variable "custom_script_extension_version" {
  description = "Azure Custom Script extension version."
  default     = "2.0"
}

variable "azuread_sql_admins_group" {
  description = "Azure SQL administrators group."
  default     = null
  type        = object({ name = string, object_id = string })
}

variable "awx_admin_username" {
  description = "AWX administrator account name."
  default     = "awx"
}

variable "awx_admin_password" {
  description = "AWX administrator account password."
  default     = "AzAwxAdmin"
}

variable "awx_secret_key" {
  description = "AWX credential encrytion key."
  default     = null
  type        = string
}

variable "awx_version" {
  description = "AWX version."
  default     = "11.2.0"
}

variable "awx_database_name" {
  description = "AWX database name."
  default     = "awx"
}

variable "awx_database_server_type" {
  description = "AWX database server placement type. Valid values are Azure, Local, External."
  default     = "Azure"
}

variable "awx_database_server_username" {
  description = "AWX database user account. If awx_database_server_type is set to 'Azure' this user account is granted server administrator."
  default     = "AzSqlSaAdmin"
}

variable "awx_database_server_password" {
  description = "AWX database user account password."
  default     = null
  type        = string
}

variable "awx_database_server_port" {
  description = "AWX database server port."
  default     = "5432"
}

variable "awx_database_server_external_name" {
  description = "Used when awx_database_server_type is set to 'External'. Must be set to server FQDN or IP address."
  default     = null
  type        = string
}

variable "awx_database_server_azure_suffix" {
  description = "Database server name suffix. Used when awx_database_server_type is set to 'Azure'."
  default     = "-error"
}

variable "awx_database_server_azure_storage_mb" {
  description = "Database server storage size. Used when awx_database_server_type is set to 'Azure'."
  default     = 51200
}

variable "awx_database_server_azure_sku_name" {
  description = "Specifies the SKU Name for this PostgreSQL Server. The name of the SKU, follows the tier + family + cores pattern (e.g. B_Gen4_1, GP_Gen5_8)"
  default     = "B_Gen5_1"
}

variable "awx_database_server_azure_version" {
  description = "Specifies the version of PostgreSQL to use. Valid values are 9.5, 9.6, 10, 10.0, and 11."
  default     = "11"
}

variable "awx_database_server_azure_ssl_enforcement" {
  description = "Specifies if SSL should be enforced on connections."
  default     = true
}

variable "awx_database_server_azure_backup_retention_days" {
  description = "Backup retention days for the server, supported values are between 7 and 35 days."
  default     = 7
}

variable "awx_database_server_azure_geo_redundant_backup" {
  description = "Turn Geo-redundant server backups on/off."
  default     = false
}

variable "awx_database_server_azure_auto_grow" {
  description = "Storage auto-grow prevents your server from running out of storage and becoming read-only."
  default     = true
}

variable "awx_database_azure_charset" {
  description = "Specifies the Charset for the PostgreSQL Database." # https://www.postgresql.org/docs/current/multibyte.html
  default     = "UTF8"
}

variable "awx_database_azure_collation" {
  description = "Specifies the Collation for the PostgreSQL Database." # https://www.postgresql.org/docs/current/collation.html
  default     = "English_United States.1252"
}

variable "module_depends_on" {
  description = "Names of resources this module should depend upon."
  default     = null
  type        = any
}
