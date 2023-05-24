variable "application" {
  description = "Application name."
  default     = "Private Duty"
}

variable "application_prefix" {
  description = "Application prefix."
  default     = "pd"
}

variable "environment" {
  description = "Environment name."
  default     = "QA"
}

variable "environment_prefix" {
  description = "Environment prefix to use."
  default     = "qa"
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

variable "local_administrators" {
  description = "List of domain users/groups which should be part of local Administrators group on all servers in the environment."
  default     = ["PD_Dev"]
  type        = list(string)
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

variable "lb_ip" {
  description = "Last octet of the IP address which should be allocated for the internal Azure Load Balancer for the web servers."
  default     = 16
}

variable "lb_load_distribution" {
  description = "Specifies which parameters should be included in determining whether a client should be handled by the same virtual machine in the backend pool. Valid values are: 'Default', 'SourceIP', 'SourceIPProtocol'."
  default     = "Default"
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
  default     = "https://proddscstg.blob.core.windows.net/software/MsSql/SQL2019EA/SW_DVD9_NTRL_SQL_Svr_Ent_Core_2019Dec2019_64Bit_English_OEM_VL_X22-22120.ISO"
}

variable "ssms_install_path" {
  description = "Location of the .exe file with MS SQL Server Management Studio setup"
  default     = "https://proddscstg.blob.core.windows.net/software/MsSql/SSMS/SSMS-Setup-ENU.18.10.exe"
}

variable "ssrs_service_account" {
  description = "Report Server service account."
  default     = "PD_QA_SSRS"
}

variable "ssrs_service_password" {
  description = "Password for the Report Server service account."
  default     = ""
}

variable "ssrs_sql_server_user" {
  description = "Username of the domain account used to initialize SSRS on a remote SQL Server virtual machine."
  default     = "PD_QA_SQL_SSRS"
}

variable "ssrs_sql_server_pswd" {
  description = "Password of the domain account used to initialize SSRS on a remote SQL Server virtual machine."
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

variable "deployment_agent_user" {
  description = "Username of the runAs account including domain or local host for Azure Pipelines Agent."
  default     = "build"
}

variable "deployment_agent_pswd" {
  description = "Password of the runAs account for Azure Pipelines Agent."
  default     = ""
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

variable "microsoft_antimalware_extension_version" {
  description = "Version of the Microsoft Antimalware extension to use."
  default     = "1.5"
}

variable "azure_devops_spn_displayname" {
  description = "Display name of the Azure DevOps service principal that would be used to access development subscription."
  default     = "MatrixCareHHP-HH-AzDevOps"
}

variable "aad_env_access_group" {
  description = "Display name of the Azure AD group which should be granted abilities to log in to the VMs and trigger automation runbooks runs."
  default     = "AzureRdpPrivateDuty"
}

variable "aad_groups" {
  description = "List of Azure AD groups that should have the access to the Azure Key Vault."
  default     = ["AzureMxpdKv", "AzureOpsGroup"]
  type        = set(string)
}

variable "sftp_triton_dest_ip" {
  description = "Destination IP address for the triton SFTP site."
  default     = "71.127.45.76"
  type        = string
}

variable "pd_sftp_tellus" {
  description = "Destination IP address for the Capario's SFTP site."
  default     = ["52.87.210.195", "52.61.148.180", "96.127.63.18", "52.61.148.180"]
  type        = list
}

variable "ftps_soneto_dest_ip" {
  description = "Destination IP address for the soneto ftps."
  default     = "52.173.245.59"
  type        = string
}

variable "alvaria_inbound" {
  description = "alvaria inbound source IP's"
  default     = ["54.204.51.220", "34.198.193.122"]
  type        = list
}