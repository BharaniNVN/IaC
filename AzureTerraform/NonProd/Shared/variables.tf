variable "application" {
  description = "Application name."
  default     = "NonProd"
}

variable "application_prefix" {
  description = "Application prefix."
  default     = "np"
}

variable "environment" {
  description = "Environment name."
  default     = "Shared"
}

variable "environment_prefix" {
  description = "Environment prefix to use."
  default     = "sh"
}

variable "location" {
  description = "Azure region."
  default     = "East US 2"
}

variable "service_endpoints" {
  description = "List of service endpoints."
  default     = ["Microsoft.AzureCosmosDB", "Microsoft.KeyVault", "Microsoft.Sql", "Microsoft.ServiceBus", "Microsoft.AzureActiveDirectory", "Microsoft.Storage"]
}

variable "vpn_type" {
  description = "The routing type of the virtual network gateway."
  default     = "RouteBased"
}

variable "vpn_sku" {
  description = "Configuration of the size and capacity of the virtual network gateway."
  default     = "Standard"
}

variable "onprem_s2s_ip" {
  description = "Public endpoint of the edge device on-prem."
  default     = "24.206.46.178"
}

variable "cerner_s2s_ip" {
  description = "Public endpoint of the edge device on-prem."
  default     = "159.140.206.252"
}

variable "onprem_local_addresses" {
  description = "On-prem local address space which should be accessed from Azure site."
  default     = ["10.4.0.0/23", "10.0.4.0/24", "10.1.1.0/24", "10.1.0.0/24", "10.3.0.0/24"]
}

variable "cerner_local_addresses" {
  description = "Cerner local address space which should be accessed from Azure site."
  default     = ["159.140.200.69/32", "159.140.200.141/32", "159.140.200.142/32", "159.140.200.150/32"]
}

variable "vpn_shared_key" {
  description = "On-prem VPN shared key"
  default     = ""
}

variable "cerner_vpn_shared_key" {
  description = "Cerner VPN shared key"
  default     = ""
}

variable "local_admin_user" {
  description = "Local administrative account."
  default     = "BtHHHAzureAdmin"
}

variable "local_admin_pswd" {
  description = "Password for local administrative account."
  default     = ""
}

variable "domain_name" {
  description = "Internal domain name."
  default     = "nc.ehomecare.com"
}

variable "domain_admin_user" {
  description = "Domain admin account used to promote new Domain Controllers in CAWDMZ domain."
  default     = "IACADMIN"
}

variable "domain_admin_pswd" {
  description = "Password for domain admin account in CAWDMZ domain."
  default     = ""
}

variable "domain_join_user" {
  description = "Account with Domain Join privilege level to join a new server to the CAWDMZ domain."
  default     = "IACJOIN"
}

variable "domain_join_pswd" {
  description = "Password for the account with Domain Join privilege level."
  default     = ""
}

variable "dsc_extension_version" {
  description = "Version of the DSC extension to use."
  default     = "2.83"
}

variable "solution_name" {
  description = "Name(s) of the solutions for Log Analytics workspace."
  default     = ["AntiMalware", "AzureAppGatewayAnalytics", "KeyVaultAnalytics", "SecurityCenterFree", "VMInsights", "AzureWebAppsAnalytics", "SQLAssessment", "AzureSQLAnalytics"]
}

variable "custom_script_extension_version" {
  description = "Version of the Custom Script extension to use."
  default     = "1.10"
}

variable "log_analytics_extension_version" {
  description = "Version of the Azure Log Analytics Agent extension to use for different OS."
  default     = { "windows" = "1.0", "linux" = "1.11" }
  type        = object({ windows = string, linux = string })
}

variable "tags" {
  description = "Tags to organize Azure resources."
  type        = map(string)
  default = {
    terraform = "true"
  }
}

variable "office_public_ip_address" {
  description = "Office or datacenter name and its public IP address in the format of key/value pair."
  default = {
    "Aberdeen" = "194.74.99.26"
    "Glasgow"  = "62.6.58.58"
    "Raleigh"  = "24.206.46.178"
    "Vector"   = "194.44.211.246"
    "HCF"      = "12.160.98.2"
  }
}

variable "key_vault_resource_group_name" {
  description = "Name of the resource group where key vault was deployed to."
  default     = "NonprodTerraform-rg"
}

variable "key_vault_name" {
  description = "Name of the key vault which holds all shared values."
  default     = "NonprodTerraformKv"
}

variable "code_signing_matrixcare_certificate_secret_name" {
  description = "Name of the key vault secret which contains the code signing pfx certificate value for MatrixCare, Inc."
  default     = "codeSigning-matrixcare"
}

variable "sfsso_brightree_net_certificate_secret_name" {
  description = "Name of the key vault secret which contains the pfx certificate value for sfsso.brightree.net domain."
  default     = "sfsso-brightree-net-nonprod"
}

variable "community_matrixcare_com_certificate_secret_name" {
  description = "Name of the key vault secret which contains the pfx certificate value for community.matrixcare.com domain."
  default     = "community-matrixcare-com-nonprod"
}

variable "ehomecare_com_certificate_secret_name" {
  description = "Name of the key vault secret which contains the pfx certificate value for *ehomecare.com domain."
  default     = "ehomecare-com-nonprod"
}

variable "sendgrid_management_api_key_secret_name" {
  description = "Name of the key vault secret which holds SendGrid management API key value."
  default     = "SendgridManagementAPIKey"
}

variable "sendgrid_server_name_secret_name" {
  description = "Name of the key vault secret which holds SendGrid server name value."
  default     = "SendgridServerName"
}

variable "public_ip_domain_suffix" {
  description = "Suffix used for the domain label name of the public IP."
  default     = "-hhh"
}

variable "alienvault_admin_user" {
  description = "Username for local admin account for AlienVault VM"
  default     = "sysadmin"
}

variable "alienvault_admin_pswd" {
  description = "Password for local admin account for AlienVault VM"
  default     = ""
}

variable "dependency_agent_extension_version" {
  description = "Version of the Dependency Agent extension to use."
  default     = "9.10"
}

variable "microsoft_antimalware_extension_version" {
  description = "Version of the Microsoft Antimalware extension to use."
  default     = "1.5"
}

variable "nxlog_conf" {
  description = "Location for the Nxlog Conf file"
  default     = "https://proddscstg.blob.core.windows.net/software/nxlog/conf/Dev/nxlog.conf"
}

variable "nxlog_pem" {
  description = "Location for the Nxlog Pem file"
  default     = "https://proddscstg.blob.core.windows.net/software/nxlog/cert/Dev/USM-Anywhere-Syslog-CA.pem"
}

variable "sql_sa_pswd" {
  description = "Password for SA account which will be set during SQL installation."
  default     = ""
}

variable "sql_service_user" {
  description = "Account which should run SQL server DB engine."
  default     = "sqlserverservice"
}

variable "sql_service_pswd" {
  description = "Password for account which should run SQL server DB engine."
  default     = ""
}

variable "sql_agent_user" {
  description = "Account which should run SQL server agent."
  default     = "sqlserveragent"
}

variable "sql_agent_pswd" {
  description = "Password for account which should run SQL server agent."
  default     = ""
}

variable "sql_iso_path" {
  description = "Location of the .ISO file with MS SQL 2017 setup"
  default     = "https://proddscstg.blob.core.windows.net/software/MsSql/SQL2017EA/SW_DVD9_NTRL_SQL_Svr_Ent_Core_2017_64Bit_English_OEM_VL_X21-56995.ISO"
}

variable "ssms_install_path" {
  description = "Location of the .exe file with MS SQL Server Management Studio setup"
  default     = "https://proddscstg.blob.core.windows.net/software/MsSql/SSMS/SSMS-Setup-ENU-2018.3.1.exe"
}

variable "azure_devops_extension_version" {
  description = "Version of the Azure Pipelines Agent extension to use."
  default     = "1.27"
}

variable "azure_devops_account" {
  description = "Complete organization url for Azure DevOps account. For example, https://dev.azure.com/organizationName"
  default     = "MatrixCareHHP"
}

variable "azure_devops_project" {
  description = "Azure DevOps Team Project which has the deployment group defined in it."
  default     = "HH"
}

variable "azure_devops_pat_token" {
  description = "The Personal Access Token which would be used to authenticate against Azure DevOps organization to download and configure agent."
  default     = ""
}

variable "builtin_azure_policy_definition_names" {
  description = "List of builtin Azure Policy definition names."
  default = [
    "ed7c8c13-51e7-49d1-8a43-8490431a0da2", # "Deploy Diagnostic Settings for Key Vault to Event Hub"
  ]
  type = set(string)
}

variable "dns_records_external" {
  description = "List of the 'A' DNS records which should be created in the domain zone. In addition, a firewall opening will be created towards the IP (port 445)"
  default     = [{ name = "shpopsazmxhhpsa", zone = "privatelink.file.core.windows.net", ports = ["445"], protocols = ["TCP"] }]
  type        = list(object({ name = string, zone = string, ports = list(string), protocols = list(string) }))
}

variable "dns_zone_name" {
  description = "Name of the zone for DNS domain mxhhpdev.com."
  default     = "mxhhpdev.com"
  type        = string
}

variable "dns_zone_resource_group_name" {
  description = "Name of the resource group for DNS domain mxhhpdev.com."
  default     = "mxhhpdev.com-rg"
  type        = string
}

variable "external_domain_name" {
  description = "External domain name which is used to publish services for clients access."
  default     = "mxhhpdev.com"
  type        = string
}

variable "mxhhpdev_com_certificate_order_name" {
  description = "Name of the certificate order for mxhhpdev.com."
  default     = "MxHhpDevWildcardCert"
  type        = string
}

variable "mxhhpdev_com_certificate_order_resource_group_name" {
  description = "Name of the resource group for certificate order for mxhhpdev.com domain."
  default     = "mxhhpdev.com-rg"
  type        = string
}

variable "pipelines_agent_subnet_resource_secret_name" {
  description = "Azure Key Vault secret name holding subnet resource data used by pipelines agent."
  default     = "PipelinesAgentSubnetResource"
  type        = string
}

variable "sftp_deyta_ip_address" {
  description = "Destination IP address for the deyta's SFTP site."
  default     = "50.57.29.69"
  type        = string
}

variable "sftp_hc3_ip_address" {
  description = "Destination IP address for the hc3's SFTP site."
  default     = "66.180.14.134"
  type        = string
}

variable "sftp_matrixcarehhp_ip_address" {
  description = "Destination IP address for the MatrixCareHHP's SFTP site."
  default     = "23.100.231.39"
  type        = string
}

variable "sftp_rs_ip_address" {
  description = "Destination IP address for the rs's SFTP site."
  default     = "184.106.74.103"
  type        = string
}

variable "sftp_tellus_ip_address" {
  description = "Destination IP address for the tellus's SFTP site."
  default     = "52.87.210.195"
  type        = string
}

variable "sftp_waystar_ip_address" {
  description = "Destination IP address for the waystar's SFTP site."
  default     = "69.2.197.40"
  type        = string
}

variable "bloomington_ip" {
  description = "Public endpoint of the edge device on-prem."
  default     = "12.2.55.2"
}

variable "bloomington_local_addresses" {
  description = "bloomington local address space which should be accessed from Azure site."
  default     = ["10.2.0.0/16"]
}

variable "coral_ip" {
  description = "Public endpoint of the edge device on-prem."
  default     = "12.167.82.180"
}

variable "coral_local_addresses" {
  description = "coral local address space which should be accessed from Azure site."
  default     = ["10.30.0.0/16"]
}

variable "bloomington_vpn_shared_key" {
  description = "bloomington VPN shared key"
  default     = ""
}

variable "coral_vpn_shared_key" {
  description = "coral VPN shared key"
  default     = ""
}

variable "sftp_capario_ip_address" {
  description = "Destination IP address for the Capario's SFTP site."
  default     = ["199.30.189.31","107.21.141.128"]
  type        = list
}

variable "disk_size_gb" {
  description = "VM OS Disk Space"
  type        = string
  default     = "254"
}