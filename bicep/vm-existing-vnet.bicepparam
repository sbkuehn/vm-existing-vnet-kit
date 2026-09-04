// vm-existing-vnet.bicepparam
// Author: Shannon Eldridge-Kuehn
// Created: 2026-09-04
//
// Example parameter file. Copy to a *.local.bicepparam file (gitignored) and
// fill in real values, or export VM_ADMIN_PASSWORD before deploying.

using './vm-existing-vnet.bicep'

param vmName = 'vm-app-01'
param vmSize = 'Standard_D2s_v5'
param adminUsername = 'azureadmin'
param adminPassword = readEnvironmentVariable('VM_ADMIN_PASSWORD', '')

param existingVnetResourceGroup = 'rg-network-prod'
param existingVnetName = 'vnet-hub-prod'
param existingSubnetName = 'snet-servers'

param tags = {
  environment: 'prod'
  owner: 'platform-team'
  deployedWith: 'bicep'
}
