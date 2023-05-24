variable "cusupvnt01_name" {
  description = "Name of the remote Vnet"
  default     = "CUSUPVNT01"
  type        = string
}

variable "cusupvnt01_resource_group_name" {
  description = "Name of the resource group of the remote Vnet CUSUPVNT01"
  default     = "CUSUPRSGSH01"
  type        = string
}

variable "cusupvnt01_subscription_id" {
  description = "Subscription of the remote organization with Vnet CUSUPVNT01"
  default     = "f7fcaa65-2b1c-468d-95f3-0284d2ec29c1"
  type        = string
}

variable "hub_vnet_address_space" {
  description = "VNET address space for HUB"
  default     = "10.105.64.0/22"
  type        = string
}

variable "hub_fw_subnet_address_space" {
  description = "Address space for firewall subnet"
  default     = "10.105.64.0/24"
  type        = string
}

variable "key_vault_name" {
  description = "Name of the key vault which holds all shared values."
  default     = "ProdTerraformKv"
  type        = string
}

variable "key_vault_resource_group_name" {
  description = "Name of the resource group where key vault was deployed to."
  default     = "ProdTerraform-rg"
  type        = string
}

variable "location" {
  description = "Azure region."
  default     = "North Central US"
  type        = string
}

variable "pipelines_agent_subnet_resource_secret_name" {
  description = "Azure Key Vault secret name holding subnet resource data used by pipelines agent."
  default     = "PipelinesAgentSubnetResource"
  type        = string
}

variable "prefix" {
  description = "The Prefix used for all resources"
  default     = "hub"
  type        = string
}

variable "public_ip_domain_suffix" {
  description = "Suffix used for the domain label name of the public IP."
  default     = "-hhh"
  type        = string
}

variable "remote_tenant_id" {
  description = "Tenant ID of the remote organization"
  default     = "6a55553e-1afe-4c39-8821-b040f10c6588"
  type        = string
}

variable "sftp_capario_ip_address" {
  description = "Destination IP address for the Capario's SFTP site."
  default     = "199.30.189.31"
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

variable "tags" {
  description = "Tags to organize Azure resources."
  type        = map(string)
  default = {
    terraform = "true"
  }
}
