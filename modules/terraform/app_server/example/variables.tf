variable "location" {
  default = "North Central US"
}

variable "env" {
  default = "druniq"
}

variable "domain_netbios_name" {
  default = "TEST"
}

variable "service_account" {
  default = "testsvc"
}

variable "ssis_service_account" {
  default = "testssis"
}

variable "hangfire_service_account" {
  default = "testhangfire"
}

variable "afo2_vm_starting_ip" {
  default = 15
}

variable "afo4_vm_starting_ip" {
  default = 20
}

variable "afo5_vm_starting_ip" {
  default = 25
}

variable "afo6_vm_starting_ip" {
  default = 30
}

variable "azure_devops_account" {
  default = ""
}

variable "azure_devops_project" {
  default = ""
}

variable "azure_devops_pat_token" {
  default = ""
}
