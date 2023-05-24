variable "application" {
  description = "Application name."
  default     = "Revenue Cycle Management"
}

# variable "application_prefix" {
#   description = "Application prefix."
#   default     = "rcm"
# }

variable "deprecated_application_prefix" {
  description = "Application prefix."
  default     = "CodingCenter"
}

variable "environment" {
  description = "Environment name."
  default     = "Dev"
}

variable "environment_prefix" {
  description = "Environment prefix to use."
  default     = "dev"
}

variable "tags" {
  description = "Tags to organize Azure resources."
  type        = map(string)
  default = {
    terraform = "true"
  }
}

variable "location" {
  description = "Azure region."
  default     = "East US 2"
}

variable "subnet_address_prefixes" {
  description = "Coding Center subnet address prefix"
  default     = ["10.105.134.0/27"]
}

variable "azure_sql_version" {
  description = "The version for the new server. Valid values are: 2.0 (for v11 server) and 12.0 (for v12 server)"
  default     = "12.0"
}

variable "azure_sql_admin" {
  description = "The administrator login name for the new server"
  default     = "AzSqlSaAdmin"
}

variable "azure_sql_admin_pswd" {
  description = "The password associated with the administrator user"
  default     = ""
}

variable "azure_mssql_database_sku_name" {
  description = "Name of the Azure SQL database sku."
  default     = "S0"
}

variable "dotnet_framework_version" {
  description = ".NET Framework version used at app service. Possible values are 'v2.0' (= .net 3.5) or 'v4.0' (= latest stable .net 4.x.x)"
  default     = "v4.0"
}

variable "remote_debugging_version" {
  description = "Version of Visual Studio should the Remote Debugger be compatible with. Possible values are VS2012, VS2013, VS2015 and VS2017"
  default     = "VS2017"
}

variable "subnet_ids" {
  type = list
  default = ["/subscriptions/ed7795be-8352-41a1-beb8-548c490c07c7/resourceGroups/bthhhterraformnonprod-rg/providers/Microsoft.Network/virtualNetworks/bthhhterraformnonprod-vnet/subnets/nonprodcodingcenter-codingcenter-as-subnet", "/subscriptions/ed7795be-8352-41a1-beb8-548c490c07c7/resourceGroups/nonprodpipelinesagent-rg/providers/Microsoft.Network/virtualNetworks/nonprodpipelinesagent-vnet/subnets/pipelinesagentaci-subnet"]
  description = "subnet ids"
}