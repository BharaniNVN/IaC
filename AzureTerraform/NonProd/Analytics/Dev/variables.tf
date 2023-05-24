variable "application" {
  description = "Application name."
  default     = "MyAnalytics"
}

variable "application_prefix" {
  description = "Application prefix."
  default     = "ana"
}

variable "environment" {
  description = "Environment name."
  default     = "Dev"
}

variable "environment_prefix" {
  description = "Environment prefix to use."
  default     = "dev"
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

variable "sql_svc_usr" {
  description = "Account which should run SQL server DB engine"
  default     = "appmgr"
}

variable "sql_svc_pswd" {
  description = "Password for account which should run SQL server DB engine"
  default     = ""
}

variable "sql_agent_user" {
  description = "Account which should run SQL server Agent"
  default     = "sqlserveragent"
}

variable "sql_agent_pswd" {
  description = "Password for account which should run SQL server Agent"
  default     = ""
}

variable "azure_sql_admin_user" {
  description = "Username for admin account at Azure SQL server"
  default     = "AzSqlSaAdmin"
}

variable "azure_sql_admin_pswd" {
  description = "Password for admin account at Azure SQL server"
  default     = ""
}

variable "sql_sa_pswd" {
  description = "Password for SA account of the SQL Server"
  default     = ""
}

variable "sql_login_adfuser_name" {
  description = "Username of SQL user with RO permissions to Staging DB. Will come from Release Variable group"
  default     = "adfuser"
}

variable "sql_login_adfuser_pswd" {
  description = "Password of SQL user with RO permissions to Staging DB"
  default     = ""
}

variable "ir_name" {
  description = "Nmae of the Integration Runtime to be created on ADF"
  default     = "SqlOnPremIR1"
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

variable "log_analytics_extension_version" {
  description = "Version of the Azure Log Analytics Agent extension to use for different OS."
  default     = { "windows" = "1.0", "linux" = "1.11" }
  type        = object({ windows = string, linux = string })
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

variable "dependency_agent_extension_version" {
  description = "Version of the Dependency Agent extension to use."
  default     = "9.10"
}

variable "deployment_agent_user" {
  description = "Username of the runAs account including domain or local host for Azure Pipelines Agent."
  default     = "MXHHPDEV\\\\deployagent"
}

variable "deployment_agent_pswd" {
  description = "Password of the runAs account for Azure Pipelines Agent."
  default     = ""
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
