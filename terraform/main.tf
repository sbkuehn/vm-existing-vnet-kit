# main.tf
# Author: Shannon Eldridge-Kuehn
# Created: 2026-09-04
# Repo:   https://github.com/sbkuehn/vm-existing-vnet-kit
#
# Deploys a Windows Server VM and NIC into an existing virtual network subnet.
# The vNet and subnet are read through data sources and are never created or
# modified by this configuration.

# ---------- Lookups (read only, nothing created) ----------

data "azurerm_resource_group" "app" {
  name = var.app_resource_group
}

data "azurerm_subnet" "existing" {
  provider             = azurerm.network
  name                 = var.existing_subnet_name
  virtual_network_name = var.existing_vnet_name
  resource_group_name  = var.existing_vnet_resource_group
}

# ---------- New resources ----------

resource "azurerm_network_interface" "vm" {
  name                = "nic-${var.vm_name}"
  location            = data.azurerm_resource_group.app.location
  resource_group_name = data.azurerm_resource_group.app.name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = data.azurerm_subnet.existing.id
    private_ip_address_allocation = var.private_ip_address == null ? "Dynamic" : "Static"
    private_ip_address            = var.private_ip_address
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                  = var.vm_name
  computer_name         = var.vm_name
  location              = data.azurerm_resource_group.app.location
  resource_group_name   = data.azurerm_resource_group.app.name
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.vm.id]
  tags                  = var.tags

  patch_mode               = "AutomaticByPlatform"
  enable_automatic_updates = true

  os_disk {
    name                 = "osdisk-${var.vm_name}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  boot_diagnostics {}
}
