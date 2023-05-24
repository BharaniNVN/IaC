variable "application" {
  description = "Application name."
  default     = "Prod"
}

variable "application_prefix" {
  description = "Application prefix."
  default     = "p"
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
  default     = "North Central US"
}

variable "secondary_location" {
  description = "Azure region for Log Analytics."
  default     = "East US"
}

variable "local_admin_user" {
  description = "Local administrative account."
  default     = "BtHHHAzureAdmin"
}

variable "local_admin_pswd" {
  description = "Password for local administrative account."
  default     = ""
}

variable "internal_domain" {
  description = "Internal domain."
  default     = "cawprod.careanyware.com"
}

variable "dmz_domain" {
  description = "DMZ domain name."
  default     = "cawdmz.careanyware.com"
}

variable "cawprod_admin_user" {
  description = "Domain admin account used to promote new Domain Controllers in CAWPROD domain."
  default     = "IACADMIN"
}

variable "cawprod_admin_pswd" {
  description = "Password for domain admin account in CAWPROD domain."
  default     = ""
}

variable "cawprod_join_user" {
  description = "Account with Domain Join privilege level to join a new server to the CAWPROD domain."
  default     = "IACJOIN"
}

variable "cawprod_join_pswd" {
  description = "Password for the account with Domain Join privilege level."
  default     = ""
}

variable "cawdmz_admin_user" {
  description = "Domain admin account used to promote new Domain Controllers in CAWDMZ domain."
  default     = "IACADMIN"
}

variable "cawdmz_admin_pswd" {
  description = "Password for domain admin account in CAWDMZ domain."
  default     = ""
}

variable "cawdmz_join_user" {
  description = "Account with Domain Join privilege level to join a new server to the CAWDMZ domain."
  default     = "IACJOIN"
}

variable "cawdmz_join_pswd" {
  description = "Password for the account with Domain Join privilege level."
  default     = ""
}

variable "sql_sa_pswd" {
  description = "Password for SA account which will be set during SQL installation."
  default     = ""
}

variable "sql_svc_user" {
  description = "Account which should run SQL server DB engine."
  default     = "sqlserverservice"
}

variable "sql_svc_pswd" {
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

variable "sftp_admin_user" {
  description = "Name of the SFTP local administrator account which will be created during install."
  default     = "SftpAdmin"
}

variable "sftp_admin_pswd" {
  description = "Password for the SFTP local administrator account which will be created during install."
  default     = ""
}

variable "tags" {
  description = "Tags to organize Azure resources."
  type        = map(string)
  default = {
    terraform = "true"
  }
}

variable "dsc_extension_version" {
  description = "Version of the DSC extension to use."
  default     = "2.83"
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

variable "solution_name" {
  description = "Name(s) of the solutions for Log Analytics workspace."
  default     = ["AntiMalware", "AzureAppGatewayAnalytics", "KeyVaultAnalytics", "NetworkMonitoring", "SecurityCenterFree", "ServiceMap", "VMInsights", "AzureWebAppsAnalytics", "SQLAssessment", "AzureSQLAnalytics"]
}

variable "dependency_agent_extension_version" {
  description = "Version of the Dependency Agent extension to use."
  default     = "9.10"
}

variable "er_type" {
  description = "The routing type of the virtual network gateway used with ExpressRoute."
  default     = "RouteBased"
}

variable "er_sku" {
  description = "Configuration of the size and capacity of the virtual network gateway used with ExpressRoute."
  default     = "Standard"
}

variable "express_route_circuit_id" {
  description = "The ID of the ExpressRoute circuit."
  default     = "/subscriptions/0f67b021-5b3d-4f38-973a-8bcddde64f72/resourceGroups/NetworkObjects-RG/providers/Microsoft.Network/expressRouteCircuits/expressRoute"
}

variable "office_public_ip_address" {
  description = "Office or datacenter name and its public IP address in the format of key/value pair."
  default = {
    "Aberdeen"      = "194.74.99.26"
    "Glasgow"       = "62.6.58.58"
    "Raleigh"       = "24.206.46.178"
    "Peak10Raleigh" = "72.15.246.30"
    "HCF"           = "12.160.98.2"
  }
}

variable "nonprod_fw_dns_names" {
  description = "List of Public DNS names of NonProd Azure Firewall"
  default     = ["nonprod-hhh-fw.eastus2.cloudapp.azure.com"]
}

variable "key_vault_resource_group_name" {
  description = "Name of the resource group where key vault was deployed to."
  default     = "ProdTerraform-rg"
}

variable "key_vault_name" {
  description = "Name of the key vault which holds all shared values."
  default     = "ProdTerraformKv"
}

variable "careanyware_certificate_secret_name" {
  description = "Name of the key vault secret which contains the pfx certificate value for careanyware.com domain."
  default     = "wildcard-careanyware-com"
}

variable "healthcarefirst_certificate_secret_name" {
  description = "Name of the key vault secret which contains the pfx certificate value for healthcarefirst.com domain."
  default     = "wildcard-healthcarefirst-com"
}

variable "sfsso_brightree_net_certificate_secret_name" {
  description = "Name of the key vault secret which contains the pfx certificate value for sfsso.brightree.net domain."
  default     = "sfsso-brightree-net"
}

variable "community_matrixcare_com_certificate_secret_name" {
  description = "Name of the key vault secret which contains the pfx certificate value for community.matrixcare.com domain."
  default     = "community-matrixcare-com"
}

variable "ehomecare_com_certificate_secret_name" {
  description = "Name of the key vault secret which contains the pfx certificate value for *ehomecare.com domain."
  default     = "wildcard-ehomecare-com"
}

variable "sendgrid_management_api_key_secret_name" {
  description = "Name of the key vault secret which holds SendGrid management API key value."
  default     = "SendgridManagementAPIKey"
}

variable "sendgrid_server_name_secret_name" {
  description = "Name of the key vault secret which holds SendGrid server name value."
  default     = "SendgridServerName"
}

variable "alienvault_admin_user" {
  description = "Username for local admin account for AlienVault VM"
  default     = "sysadmin"
}

variable "alienvault_admin_pswd" {
  description = "Password for local admin account for AlienVault VM"
  default     = ""
}

variable "microsoft_antimalware_extension_version" {
  description = "Version of the Microsoft Antimalware extension to use."
  default     = "1.5"
}

variable "nxlog_conf" {
  description = "Location for the Nxlog Conf file"
  default     = "https://proddscstg.blob.core.windows.net/software/nxlog/conf/Prod/nxlog.conf"
}

variable "nxlog_pem" {
  description = "Location for the Nxlog Pem file"
  default     = "https://proddscstg.blob.core.windows.net/software/nxlog/cert/Prod/USM-Anywhere-Syslog-CA.pem"
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

variable "azure_devops_spn_displayname" {
  description = "Display name of the Azure DevOps service principal that would be used to access production subscription."
  default     = "MatrixCareHHP-HHP-0f67b021-5b3d-4f38-973a-8bcddde64f72"
}

variable "builtin_azure_policy_definition_names" {
  description = "List of builtin Azure Policy definition names."
  default = [
    "ed7c8c13-51e7-49d1-8a43-8490431a0da2", # "Deploy Diagnostic Settings for Key Vault to Event Hub"
  ]
  type = set(string)
}

variable "dns_zone_name" {
  description = "Name of the zone for DNS domain matrixcarehhp.com."
  default     = "MatrixCareHHP.com"
  type        = string
}

variable "dns_zone_resource_group_name" {
  description = "Name of the resource group for DNS domain matrixcarehhp.com."
  default     = "MatrixCareHHPdomain-rg"
  type        = string
}

variable "external_domain_name" {
  description = "External domain name which is used to publish services for clients access."
  default     = "careanyware.com"
  type        = string
}

variable "matrixcarehhp_com_certificate_order_name" {
  description = "Name of the certificate order for matrixcarehhp.com."
  default     = "MatrixCareHhpWildcardCert"
  type        = string
}

variable "matrixcarehhp_com_certificate_order_resource_group_name" {
  description = "Name of the resource group for certificate order for matrixcarehhp.com domain."
  default     = "MatrixCareHHPdomain-rg"
  type        = string
}

variable "oracle_backup_account" {
  description = "Username of the custom account used on ORACLE servers for backup."
  default     = "orabackup"
}

variable "oracle_service_user" {
  description = "Account which should run Oracle DB engine"
  default     = "orasvc"
}

variable "oracle_service_pswd" {
  description = "Password for account which should run Oracle DB engine"
  default     = ""
}

variable "oracle_sys_pswd" {
  description = "Will be used for all system databases: SYS, SYSTEM and DBSNMP"
  default     = ""
}

variable "oracle_install_files" {
  description = "Links to the location of Oracle installation files."
  default = [
    "https://proddscstg.blob.core.windows.net/software/Oracle/OracleDatabase12c/winx64_12102_SE2_database_1of2.zip",
    "https://proddscstg.blob.core.windows.net/software/Oracle/OracleDatabase12c/winx64_12102_SE2_database_2of2.zip",
  ]
}

variable "oracle_product_name" {
  description = "Oracle product name. For example, 'Oracle 12c' or 'Oracle 19c'."
  default     = "Oracle 12c"
}

variable "oracle_product_version" {
  description = "Oracle product name. For example, for 'Oracle 12c' its '12.1.0', for 'Oracle 19c' - '19.3.0'."
  default     = "12.1.0"
}

variable "deployment_agent_user" {
  description = "Username of the runAs account including domain or local host for Azure Pipelines Agent."
  default     = "deploymentagent"
}

variable "deployment_agent_pswd" {
  description = "Password of the runAs account for Azure Pipelines Agent."
  default     = ""
}
