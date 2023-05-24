variable "application" {
  description = "Application name."
  default     = "AFO"
}

variable "application_prefix" {
  description = "Application prefix."
  default     = "afo"
}

variable "environment" {
  description = "Environment name."
  default     = "Hotfix"
}

variable "environment_prefix" {
  description = "Environment prefix to use."
  default     = "hfx"
}

variable "location" {
  description = "Azure region."
  default     = "East US 2"
}

variable "local_admin_user" {
  description = "Local administrative account."
  default     = "BtHHHAzureAdmin"
}

variable "local_admin_pswd" {
  description = "Password for local administrative account."
  default     = ""
}

variable "tags" {
  description = "Tags to organize Azure resources."
  type        = map(string)
  default = {
    terraform = "true"
  }
}

variable "key_vault_extension_version" {
  description = "Version of the Key Vault extension to use for different OS."
  default     = { "windows" = "1.0", "linux" = "2.0" }
  type        = object({ windows = string, linux = string })
}

variable "dsc_extension_version" {
  description = "Version of the DSC extension to use."
  default     = "2.83"
}

variable "log_analytics_extension_version" {
  description = "Version of the Azure Log Analytics Agent extension to use for different OS."
  default     = { "windows" = "1.0", "linux" = "1.11" }
  type        = object({ windows = string, linux = string })
}

variable "solution_name" {
  description = "Name(s) of the solutions for Log Analytics workspace."
  default     = ["AgentHealthAssessment", "AntiMalware", "ApplicationInsights", "AzureActivity", "KeyVaultAnalytics", "SecurityCenterFree", "ServiceMap", "SQLAssessment", "VMInsights"]
}

variable "app_pool_account" {
  description = "Username of the custom application pool account used on AFO and WF servers which would be used to grant necessary permissions."
  default     = "HhpWebUserHfx"
}

variable "sync_app_pool_account" {
  description = "Username of the custom application pool account used on SYNC servers which would be used to grant necessary permissions."
  default     = "HhpSyncUserHfx"
}

variable "service_account" {
  description = "Username of the custom account which would be used to grant necessary permissions."
  default     = "HhpSvcUserHfx"
}

variable "hangfire_service_account" {
  description = "Username of the custom account for HangFire service which would be used to grant necessary permissions."
  default     = "HhpHangfireUserHfx"
}

variable "ssis_service_account" {
  description = "Username of the custom account for SSIS which would be used to grant necessary permissions."
  default     = "HhpSsisUserHfx"
}

variable "que_service_account_username" {
  description = "Username of the custom account used on QUE servers which would be used to grant necessary permissions."
  default     = "HhpQueUserHfx"
}

variable "que_service_account_password" {
  description = "Password of the custom account used on QUE servers which would be used to grant necessary permissions."
  default     = ""
}

variable "oracle_backup_account" {
  description = "Username of the custom account used on ORACLE servers for backup."
  default     = "orabackup"
}

variable "afo_lb_ip" {
  description = "Last octet of the IP address which should be allocated for the internal Azure Load Balancer for the AFO servers."
  default     = 5
}

variable "login_lb_ip" {
  description = "Last octet of the IP address which should be allocated for the internal Azure Load Balancer for the LOGIN servers."
  default     = 25
}

variable "wf_lb_ip" {
  description = "Last octet of the IP address which should be allocated for the internal Azure Load Balancer for the WF servers."
  default     = 10
}

variable "sync_vm_starting_ip" {
  description = "Last octet of the IP address which should be allocated for the first SYNC virtual machine."
  default     = 15
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

variable "oracle_service_user" {
  description = "Account which should run Oracle DB engine"
  default     = "oracleservice"
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
    "https://proddscstg.blob.core.windows.net/software/Oracle/OracleDatabase19c/WINDOWS.X64_193000_db_home.zip",
  ]
}

variable "oracle_product_name" {
  description = "Oracle product name. For example, 'Oracle 12c' or 'Oracle 19c'."
  default     = "Oracle 19c"
}

variable "oracle_product_version" {
  description = "Oracle product name. For example, for 'Oracle 12c' its '12.1.0', for 'Oracle 19c' - '19.3.0'."
  default     = "19.3.0"
}

variable "nondbservers_rdp_users" {
  description = "Domain group which should be part of 'Remote Desktop Users' group on non DB related servers, e.g. except SQL/Oracle."
  default     = "AzureDevEnvRdp"
}

variable "deployment_agent_user" {
  description = "Username of the runAs account including domain or local host for Azure Pipelines Agent."
  default     = "build"
}

variable "deployment_agent_pswd" {
  description = "Password of the runAs account for Azure Pipelines Agent."
  default     = ""
}

variable "nxlog_conf" {
  description = "Location for the Nxlog Conf file"
  default     = "https://proddscstg.blob.core.windows.net/software/nxlog/conf/Dev/nxlog.conf"
}

variable "nxlog_pem" {
  description = "Location for the Nxlog Pem file"
  default     = "https://proddscstg.blob.core.windows.net/software/nxlog/cert/Dev/USM-Anywhere-Syslog-CA.pem"
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
  description = "Display name of the Azure DevOps service principal that would be used to access development subscription"
  default     = "MatrixCareHHP-HH-AzDevOps"
}

variable "azure_devops_deployment_group" {
  description = "DevOps deployment group name"
  default     = "US-Azure-EastUs2-AfoHotfix-NonProd"
}

variable "dependency_agent_extension_version" {
  description = "Version of the Dependency Agent extension to use."
  default     = "9.10"
}

variable "microsoft_antimalware_extension_version" {
  description = "Version of the Microsoft Antimalware extension to use."
  default     = "1.5"
}

variable "sftp_capario_ip_address" {
  description = "Destination IP address for the Capario's SFTP site."
  default     = ["199.30.189.31","107.21.141.128"]
  type        = list
}