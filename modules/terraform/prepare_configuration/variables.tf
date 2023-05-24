variable "vm_name" {
  description = "Names of the virtual machines which would be using target file."
  default     = [""]
  type        = list(string)
}

variable "storage_container_resource" {
  description = "Partial storage container resource with three keys for names of the resource group, storage account and storage container used for DSC."
  default     = null
  type        = object({ resource_group_name = string, storage_account_name = string, name = string })
}

variable "file_path" {
  description = "Path on the local system to the DSC configuration archive."
  default     = "test.zip"
}

variable "sas_token_validity_period" {
  description = "Validity period of the to-be generated SAS token."
  default     = "2h"
}

variable "module_depends_on" {
  description = "Names of resources this module should depend upon."
  default     = null
  type        = any
}
