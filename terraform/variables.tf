# variables.tf
# Author: Shannon Eldridge-Kuehn
# Created: 2026-09-04

variable "subscription_id" {
  description = "Subscription where the VM and NIC will be deployed."
  type        = string
}

variable "network_subscription_id" {
  description = "Subscription that owns the existing vNet. Leave null if it is the same as subscription_id."
  type        = string
  default     = null
}

variable "app_resource_group" {
  description = "Existing resource group where the VM and NIC will be deployed."
  type        = string
  default     = "rg-app-prod"
}

variable "existing_vnet_resource_group" {
  description = "Resource group that owns the existing virtual network."
  type        = string
  default     = "rg-network-prod"
}

variable "existing_vnet_name" {
  description = "Name of the existing virtual network."
  type        = string
  default     = "vnet-hub-prod"
}

variable "existing_subnet_name" {
  description = "Name of the existing subnet the NIC will join."
  type        = string
  default     = "snet-servers"
}

variable "vm_name" {
  description = "Name of the virtual machine. Also used as the computer name (15 character max for Windows)."
  type        = string
  default     = "vm-app-01"

  validation {
    condition     = length(var.vm_name) <= 15
    error_message = "Windows computer names must be 15 characters or fewer."
  }
}

variable "vm_size" {
  description = "VM size. Confirm availability in the target region before deploying."
  type        = string
  default     = "Standard_D2s_v5"
}

variable "admin_username" {
  description = "Local administrator username."
  type        = string
}

variable "admin_password" {
  description = "Local administrator password."
  type        = string
  sensitive   = true
}

variable "private_ip_address" {
  description = "Static private IP for the NIC. Leave null for dynamic allocation."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the VM and NIC."
  type        = map(string)
  default = {
    environment  = "prod"
    owner        = "platform-team"
    deployedWith = "terraform"
  }
}
