# You can easily customize your infrastructure by changing the default values below.
# No need to edit main.tf, network.tf or compute.tf files.

variable "location" {
  description = "Our Azure Region"
  default     = "polandcentral"
}

variable "rg_name" {
  description = "Resource group name"
  default     = "immich-prod"
}

variable "admin_username" {
  description = "admin username for the VM"
  default     = "immich_admin"
}

variable "disk_type" {
  description = "Our choice of a disk"
  default     = "Standard_LRS" # economic choice, will be more then enought for this exercice
}

variable "vm_sku" {
  description = "Our choice of a VM sku"
  default     = "22_04-lts" # Ubuntu 22.04 LTS - standards stable Linux choice 
}

variable "vm_size" {
  description = "The size of the Virtual Machine"
  default     = "Standard_B2s"
}

variable "immich_port" {
  description = "Port used by Immich application"
  default     = 2283 # default port
}