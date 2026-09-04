# outputs.tf
# Author: Shannon Eldridge-Kuehn
# Created: 2026-09-04

output "vm_id" {
  description = "Resource ID of the virtual machine."
  value       = azurerm_windows_virtual_machine.vm.id
}

output "nic_id" {
  description = "Resource ID of the network interface."
  value       = azurerm_network_interface.vm.id
}

output "subnet_id" {
  description = "Resource ID of the existing subnet the NIC joined."
  value       = data.azurerm_subnet.existing.id
}

output "private_ip" {
  description = "Private IP address assigned to the NIC."
  value       = azurerm_network_interface.vm.private_ip_address
}
