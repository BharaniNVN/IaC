variable "application" {
  description = "Application name."
  default     = "DR"
}

variable "application_prefix" {
  description = "Application prefix."
  default     = "dr"
}

variable "environment" {
  description = "Environment name."
  default     = "Shared"
}

# variable "environment_prefix" {
#   description = "Environment prefix to use."
#   default     = "sh"
# }

variable "location" {
  description = "Azure region."
  default     = "North Central US"
}

variable "secondary_location" {
  description = "Azure region for Log Analytics."
  default     = "East US"
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

variable "community_matrixcare_com_certificate_secret_name" {
  description = "Name of the key vault secret which contains the pfx certificate value for community.matrixcare.com domain."
  default     = "community-matrixcare-com"
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
  default     = ["AgentHealthAssessment", "AntiMalware", "AzureActivity", "AzureAppGatewayAnalytics", "KeyVaultAnalytics", "NetworkMonitoring", "SecurityCenterFree", "ServiceMap", "SQLAssessment", "VMInsights"]
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

variable "onprem_db_backup_environments" {
  description = "A list of environments which require storage account to store database backups."
  default = {
    "prod2"  = ["prod2/FULL", "ora2expdp"]
    "prod4"  = ["prod4/FULL", "ora4expdp"]
    "prod5"  = ["prod5/FULL", "ora5expdp"]
    "prod6"  = ["prod6/FULL", "ora6expdp"]
    "prod7"  = ["prod7/FULL", "ora7expdp"]
    "prod8"  = ["prod8/FULL", "ora8expdp"]
    "shared" = ["hoedb/FULL"]
  }
}

variable "external_domain_name" {
  description = "External domain name which is used to publish services for clients access."
  default     = "careanyware.com"
  type        = string
}
