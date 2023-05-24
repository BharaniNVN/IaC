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
  default     = "Prod"
}

variable "environment_prefix" {
  description = "Environment prefix to use."
  default     = "p"
}

variable "location" {
  description = "Azure region."
  default     = "North Central US"
}

# variable "afo7_lb_ip" {
#   description = "Last octet of the IP address which should be allocated for the internal Azure Load Balancer for the AFO servers."
#   default     = 34
# }

# variable "local_admin_user" {
#   description = "Local administrative account."
#   default     = "BtHHHAzureAdmin"
# }

# variable "local_admin_pswd" {
#   description = "Password for local administrative account."
#   default     = ""
# }

variable "app_pool_account" {
  description = "Account which will be granted 'Read' permission on the specific local folders used for application deployment."
  default     = "HhpWebUser"
}

# variable "service_account" {
#   description = "Username of the custom account which would be used to grant necessary permissions."
#   default     = "HhpSvcUser"
# }

# variable "hangfire_service_account" {
#   description = "Username of the custom account for HangFire service which would be used to grant necessary permissions."
#   default     = "HhpHangfireUser"
# }

# variable "ssis_service_account" {
#   description = "Username of the custom account for SSIS which would be used to grant necessary permissions."
#   default     = "HhpSsisUser"
# }

# variable "oracle_backup_account" {
#   description = "Username of the custom account used on ORACLE servers for backup."
#   default     = "orabackup"
# }

# variable "custom_script_extension_version" {
#   description = "Version of the Custom Script extension to use."
#   default     = "1.10"
# }

# variable "key_vault_extension_version" {
#   description = "Version of the Key Vault extension to use for different OS."
#   default     = { "windows" = "1.0", "linux" = "2.0" }
#   type        = object({ windows = string, linux = string })
# }

# variable "dsc_extension_version" {
#   description = "Version of the DSC extension to use."
#   default     = "2.83"
# }

# variable "log_analytics_extension_version" {
#   description = "Version of the Azure Log Analytics Agent extension to use for different OS."
#   default     = { "windows" = "1.0", "linux" = "1.11" }
#   type        = object({ windows = string, linux = string })
# }

variable "solution_name" {
  description = "Name(s) of the solutions for Log Analytics workspace."
  default     = ["AgentHealthAssessment", "AntiMalware", "ApplicationInsights", "AzureActivity", "KeyVaultAnalytics", "SecurityCenterFree", "ServiceMap", "SQLAssessment", "VMInsights"]
}

# variable "azure_devops_extension_version" {
#   description = "Version of the Azure Pipelines Agent extension to use."
#   default     = "1.27"
# }

# variable "azure_devops_account" {
#   description = "Complete organization url for Azure DevOps account. For example, https://dev.azure.com/organizationName"
#   default     = "MatrixCareHHP"
# }

# variable "azure_devops_project" {
#   description = "Azure DevOps Team Project which has the deployment group defined in it."
#   default     = "HH"
# }

# variable "azure_devops_pat_token" {
#   description = "The Personal Access Token which would be used to authenticate against Azure DevOps organization to download and configure agent."
#   default     = ""
# }

# variable "dependency_agent_extension_version" {
#   description = "Version of the Dependency Agent extension to use."
#   default     = "9.10"
# }

# variable "sql_sa_pswd" {
#   description = "Password for SA account which will be set during SQL installation."
#   default     = ""
# }

# variable "sql_svc_usr" {
#   description = "Account which should run SQL server DB engine"
#   default     = "sqlserverservice"
# }

# variable "sql_svc_pswd" {
#   description = "Password for account which should run SQL server DB engine"
#   default     = ""
# }

# variable "sql_agent_user" {
#   description = "Account which should run SQL server Agent"
#   default     = "sqlserveragent"
# }

# variable "sql_agent_pswd" {
#   description = "Password for account which should run SQL server Agent"
#   default     = ""
# }

# variable "sql_iso_path" {
#   description = "Location of the .ISO file with MS SQL 2017 setup"
#   default     = "https://proddscstg.blob.core.windows.net/software/MsSql/SQL2017EA/SW_DVD9_NTRL_SQL_Svr_Ent_Core_2017_64Bit_English_OEM_VL_X21-56995.ISO"
# }

# variable "ssms_install_path" {
#   description = "Location of the .exe file with MS SQL Server Management Studio setup"
#   default     = "https://proddscstg.blob.core.windows.net/software/MsSql/SSMS/SSMS-Setup-ENU-2018.3.1.exe"
# }

variable "tags" {
  description = "Tags to organize Azure resources."
  type        = map(string)
  default = {
    terraform = "true"
  }
}

# variable "oracle_install_files" {
#   description = "Links to the location of Oracle installation files."
#   default = [
#     "https://proddscstg.blob.core.windows.net/software/Oracle/OracleDatabase12c/winx64_12102_SE2_database_1of2.zip",
#     "https://proddscstg.blob.core.windows.net/software/Oracle/OracleDatabase12c/winx64_12102_SE2_database_2of2.zip",
#   ]
# }

# variable "oracle_product_name" {
#   description = "Oracle product name. For example, 'Oracle 12c' or 'Oracle 19c'."
#   default     = "Oracle 12c"
# }

# variable "oracle_product_version" {
#   description = "Oracle product name. For example, for 'Oracle 12c' its '12.1.0', for 'Oracle 19c' - '19.3.0'."
#   default     = "12.1.0"
# }

# variable "oracle_service_user" {
#   description = "Account which should run Oracle DB engine"
#   default     = "orasvc"
# }

# variable "oracle_service_pswd" {
#   description = "Password for account which should run Oracle DB engine"
#   default     = ""
# }

# variable "oracle_sys_pswd" {
#   description = "Will be used for all system databases: SYS, SYSTEM and DBSNMP"
#   default     = ""
# }

# variable "deployment_agent_user" {
#   description = "Username of the runAs account including domain or local host for Azure Pipelines Agent."
#   default     = "deploymentagent"
# }

# variable "deployment_agent_pswd" {
#   description = "Password of the runAs account for Azure Pipelines Agent."
#   default     = ""
# }

# variable "microsoft_antimalware_extension_version" {
#   description = "Version of the Microsoft Antimalware extension to use."
#   default     = "1.5"
# }

# variable "nxlog_conf" {
#   description = "Location for the Nxlog Conf file"
#   default     = "https://proddscstg.blob.core.windows.net/software/nxlog/conf/Prod/nxlog.conf"
# }

# variable "nxlog_pem" {
#   description = "Location for the Nxlog Pem file"
#   default     = "https://proddscstg.blob.core.windows.net/software/nxlog/cert/Prod/USM-Anywhere-Syslog-CA.pem"
# }

variable "azure_devops_spn_displayname" {
  description = "Display name of the Azure DevOps service principal that would be used to access production subscription"
  default     = "MatrixCareHHP-HHP-0f67b021-5b3d-4f38-973a-8bcddde64f72"
}