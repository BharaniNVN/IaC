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
  default     = "StandardSSD_LRS"
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
  default     = "Standard_DS2_v2"
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

variable "enable_key_vault_certificates_integration_using_extension" {
  description = "Whether recent certificates would be fetched using virtual machine extension or during virtual machine deployment only as secrets."
  default     = true
  type        = bool
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
  default     = ""
}

variable "admin_password" {
  description = "Password of the local administrator account."
  default     = ""
}

variable "patch_mode" {
  description = "Specifies the mode of in-guest patching to this Windows Virtual Machine. Possible values are 'Manual', 'AutomaticByOS' or 'AutomaticByPlatform'."
  default     = "Manual"
}

variable "timezone" {
  description = "Time zone which should be used by the windows virtual machine, activated only during creation of it. Valid values can be spot on https://docs.microsoft.com/en-us/azure/azure-sql/managed-instance/timezones-overview#list-of-supported-time-zones"
  default     = "Eastern Standard Time"
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

variable "key_vault_extension_version" {
  description = "Version of the Key Vault extension to use for different OS."
  default     = null
  type        = object({ windows = string, linux = string })
}

variable "key_vault_certificate_store_location" {
  description = "Certificate store location for Windows (\"LocalMachine\") or disk path where certificate is stored for Linux (\"/var/lib/waagent/Microsoft.Azure.KeyVault\")."
  default     = "LocalMachine"
  type        = string
}

variable "key_vault_link_on_renewal" {
  description = "Whether enable auto-rotation of SSL certificates without necessitating a re-deployment or binding. Works only for Windows (detailed information https://docs.microsoft.com/en-us/azure/service-fabric/cluster-security-certificate-management#certificate-linking-explained)."
  default     = false
  type        = bool
}

variable "key_vault_msi_client_id" {
  description = "Client ID of the user assigned identity used for authentication to Azure Key Vault. Required for user assigned identity."
  default     = null
  type        = string
}

variable "key_vault_msi_endpoint" {
  description = "Instance metadata service (IMDS) endpoint, e.g. http://169.254.169.254/metadata/identity, used for acquiring an access token for managed identity."
  default     = "http://169.254.169.254/metadata/identity"
  type        = string
}

variable "key_vault_polling_interval" {
  description = "Polling frequency in seconds for certificate update."
  default     = "3600"
  type        = string
}

variable "dsc_storage_container_resource" {
  description = "Partial storage container resource with three keys for names of the resource group, storage account and storage container used for DSC."
  default     = null
  type        = object({ resource_group_name = string, storage_account_name = string, name = string })
}

variable "dsc_zip_file_search_path" {
  description = "Path to the folder which contains zip file with DSC configuration and necessary modules."
  default     = ""
}

variable "dsc_script_file_name" {
  description = "Name of the DSC configuration script file excluding extension."
  default     = "SSRS"
}

variable "dsc_configuration_name" {
  description = "Name of the DSC configuration."
  default     = ""
}

variable "dsc_extension_version" {
  description = "Version of the DSC extension to use."
  default     = null
  type        = string
}

variable "tags" {
  description = "Tags to organize Azure resources."
  default     = {}
  type        = map(string)
}

variable "domain_name" {
  description = "Active Directory domain name."
}

variable "domain_join_account" {
  description = "Account with Domain Join privilege level to join a new server to the domain."
}

variable "domain_join_password" {
  description = "Password for the account with Domain Join privilege level."
}

variable "join_ou" {
  description = "Full distinguished name of the organizational unit (OU) for the computer object. The default value is the default OU for machine objects in the domain."
  default     = ""
}

variable "local_groups_members" {
  description = "Map of the local groups and their members."
  default     = {}
  type        = map(list(string))
}

variable "npmd_port" {
  description = "Port number used by Network Performance Monitor solution in Azure Log Analytics."
  default     = 8084
}

variable "folders_permissions" {
  description = "Map of the accounts and their access permisions for folders. If folder doesn't exist it'll be created. Should be defined in form '{\"DOMAIN\\Domain Admins\": {\"Read\": [ \"C:\\Temp\"], \"FullControl\": [\"C:\\Windows\"]}}'"
  default     = {}
  type        = map(map(list(string)))
}

variable "ssrs_install_file" {
  description = "Location of the .exe file with MS SQL Reporting Services setup"
  default     = "https://proddscstg.blob.core.windows.net/software/MsSql/SSRS2019/SQLServerReportingServices.exe"
}

variable "ssrs_edition" {
  description = "Edition of MS SQL Reporting Services."
  default     = "Development"
}

variable "ssrs_instance_name" {
  description = "Name of the SQL Server Reporting Services instance."
  default     = "SSRS"
}

variable "ssrs_database_server_name" {
  description = "Name of the SQL Server to host the Reporting Service database."
  default     = "localhost"
}

variable "ssrs_database_instance_name" {
  description = "Name of the SQL Server instance to host the Reporting Service database."
  default     = "MSSQLSERVER"
}

variable "ssrs_report_server_virtual_directory" {
  description = "Report Server Web Service virtual directory."
  default     = "ReportServer"
}

variable "ssrs_reports_virtual_directory" {
  description = "Report Manager/Report Web App virtual directory name."
  default     = "Reports"
}

variable "ssrs_report_server_reserved_url" {
  description = "Report Server URL reservations."
  default     = ["http://+:80"]
  type        = list(string)
}

variable "ssrs_reports_reserved_url" {
  description = "Report Manager/Report Web App URL reservations."
  default     = ["http://+:80"]
  type        = list(string)
}

variable "ssrs_ssl_certificate_thumbprint" {
  description = "SSL certificate thumbprint if secure access (https) to SSRS Web Portal/Report Server should be configured."
  default     = ""
  type        = string
}

variable "ssrs_service_account" {
  description = "Report Server service account."
}

variable "ssrs_service_password" {
  description = "Password for the Report Server service account."
}

variable "ssrs_sql_server_account" {
  description = "Account with privileges to connect to the SQL Server instance specified in var.ssrs_database_server_name and var.ssrs_database_instance_name, and permission to create the Reporting Services databases."
}

variable "ssrs_sql_server_password" {
  description = "Password for the account with privileges to connect to the SQL Server instance specified in var.ssrs_database_server_name and var.ssrs_database_instance_name, and permission to create the Reporting Services databases."
}

variable "nxlog_conf" {
  description = "Location for the Nxlog Conf file"
  default     = "https://proddscstg.blob.core.windows.net/software/nxlog/conf/Dev/nxlog.conf"
}

variable "nxlog_pem" {
  description = "Location for the Nxlog Pem file"
  default     = "https://proddscstg.blob.core.windows.net/software/nxlog/cert/Dev/USM-Anywhere-Syslog-CA.pem"
}

variable "custom_script_extension_version" {
  description = "Version of the Custom Script extension to use."
  default     = null
  type        = string
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

variable "azure_devops_extension_version" {
  description = "Version of the Azure Pipelines Agent extension to use."
  default     = null
  type        = string
}

variable "azure_devops_account" {
  description = "Complete organization url for Azure DevOps account. For example, https://dev.azure.com/organizationName"
  default     = ""
}

variable "azure_devops_project" {
  description = "Azure DevOps Team Project which has the deployment group defined in it."
  default     = ""
}

variable "azure_devops_deployment_group" {
  description = "Deployment Group against which deployment agent will be registered."
  default     = "Test Group"
}

variable "azure_devops_agent_tags" {
  description = "A comma separated list of tags which will be set on agent. Tags are case insensitive."
  default     = "Test tag, test tag 2, test tag 3"
}

variable "azure_devops_pat_token" {
  description = "The Personal Access Token which would be used to authenticate against Azure DevOps organization to download and configure agent."
  default     = ""
}

variable "dependency_agent_extension_version" {
  description = "Version of the Dependency Agent extension to use."
  default     = null
  type        = string
}

variable "microsoft_antimalware_extension_version" {
  description = "Version of the Microsoft Antimalware extension to use."
  default     = null
  type        = string
}

variable "microsoft_antimalware_enable_scheduled_scan" {
  description = "Defines if Sheduled scan should be enabled or not"
  default     = "true"
}

variable "microsoft_antimalware_sheduled_scan_day" {
  description = "Day in a week when scheduled scan should be performed. Can take values 0-8 (0-daily, 1-Sunday, 2-Monday, ...., 7-Saturday, 8-Disabled)"
  default     = "7"
}

variable "microsoft_antimalware_sheduled_scan_time" {
  description = "Time for scheduled scan measured in minutes after midnight. Can take values 0-1440: 60 -> 1:00AM, 120 -> 2:00AM, ..., 1380 -> 11:00PM"
  default     = "120"
}

variable "microsoft_antimalware_sheduled_scan_type" {
  description = "Quick or Full"
  default     = "Quick"
}

variable "microsoft_antimalware_exclusion_extensions" {
  description = "List of the extensions to be excluded from scanning by Microsoft Antimalware. Should be provided in syntax: [.log, .ldf]"
  default     = [""]
  type        = list(string)
}

variable "microsoft_antimalware_exclusion_files" {
  description = "List of the files to be excluded from scanning by Microsoft Antimalware. Should be provided in syntax: [D:\\\\IISlogs\\\\Logs, D:\\\\DatabaseLogs]"
  default     = [""]
  type        = list(string)
}

variable "microsoft_antimalware_exclusion_processes" {
  description = "List of the processes to be excluded from scanning by Microsoft Antimalware. Should be provided in syntax: [process1.exe, spoolsrv.exe]"
  default     = [""]
  type        = list(string)
}

variable "module_depends_on" {
  description = "Names of resources this module should depend upon."
  default     = null
  type        = any
}
