// vm-existing-vnet.bicep
// Author: Shannon Eldridge-Kuehn
// Created: 2026-09-04
// Repo:   https://github.com/sbkuehn/vm-existing-vnet-kit
//
// Deploys a Windows Server VM and NIC into an existing virtual network subnet.
// The vNet and subnet are referenced with the `existing` keyword and are never
// created or modified by this template.

metadata author = 'Shannon Eldridge-Kuehn'
metadata created = '2026-09-04'

targetScope = 'resourceGroup'

// ---------- Parameters ----------

@description('Name of the virtual machine. Also used as the computer name.')
@minLength(1)
@maxLength(15)
param vmName string = 'vm-app-01'

@description('VM size. Confirm availability in the target region before deploying.')
param vmSize string = 'Standard_D2s_v5'

@description('Local administrator username.')
param adminUsername string

@description('Local administrator password.')
@secure()
param adminPassword string

@description('Subscription that owns the existing virtual network. Defaults to the deployment subscription.')
param existingVnetSubscriptionId string = subscription().subscriptionId

@description('Resource group that owns the existing virtual network.')
param existingVnetResourceGroup string = 'rg-network-prod'

@description('Name of the existing virtual network.')
param existingVnetName string = 'vnet-hub-prod'

@description('Name of the existing subnet the NIC will join.')
param existingSubnetName string = 'snet-servers'

@description('Dynamic lets the platform pick an address. Static requires privateIpAddress.')
@allowed([
  'Dynamic'
  'Static'
])
param privateIpAllocationMethod string = 'Dynamic'

@description('Static private IP. Only used when privateIpAllocationMethod is Static.')
param privateIpAddress string = ''

@description('Region for the VM and NIC. Must match the region of the existing vNet.')
param location string = resourceGroup().location

@description('Tags applied to the VM and NIC.')
param tags object = {}

// ---------- Variables ----------

var nicName = 'nic-${vmName}'
var osDiskName = 'osdisk-${vmName}'

// ---------- Existing network (referenced, not created) ----------

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: existingVnetName
  scope: resourceGroup(existingVnetSubscriptionId, existingVnetResourceGroup)
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  parent: vnet
  name: existingSubnetName
}

// ---------- New resources ----------

resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: nicName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: privateIpAllocationMethod
          privateIPAddress: privateIpAllocationMethod == 'Static' ? privateIpAddress : null
          subnet: {
            id: subnet.id
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: vmName
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByPlatform'
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        name: osDiskName
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

// ---------- Outputs ----------

output vmId string = vm.id
output nicId string = nic.id
output subnetId string = subnet.id
output privateIp string = nic.properties.ipConfigurations[0].properties.privateIPAddress
