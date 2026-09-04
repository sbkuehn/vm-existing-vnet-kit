# Reusing an Existing NIC

Author: Shannon Eldridge-Kuehn
Created: 2026-09-04

The main templates create a new NIC for every VM, which is the normal case. Occasionally you need the opposite: attach a VM to a NIC that already exists. The usual reasons are rebuilding a VM while preserving its private IP, or a NIC the network team pre-created with specific NSG or ASG membership.

The pattern is the same one used for the subnet, applied one resource down. Drop the NIC from the template and look it up instead.

## ARM

Remove the `Microsoft.Network/networkInterfaces` resource and the `dependsOn` entry, then reference the NIC by ID:

```json
"networkProfile": {
  "networkInterfaces": [
    {
      "id": "[resourceId(parameters('existingNicResourceGroup'), 'Microsoft.Network/networkInterfaces', parameters('existingNicName'))]"
    }
  ]
}
```

## Bicep

```bicep
resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' existing = {
  name: existingNicName
  scope: resourceGroup(existingNicResourceGroup)
}

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  ...
  properties: {
    networkProfile: {
      networkInterfaces: [
        { id: nic.id }
      ]
    }
  }
}
```

## Terraform

```hcl
data "azurerm_network_interface" "existing" {
  name                = var.existing_nic_name
  resource_group_name = var.existing_nic_resource_group
}

resource "azurerm_windows_virtual_machine" "vm" {
  ...
  network_interface_ids = [data.azurerm_network_interface.existing.id]
}
```

## Gotchas

- A NIC can only be attached to one VM. If it is still attached to a deallocated or partially deleted VM, the deployment fails with `NicInUse`. Detach or delete the old VM first.
- The NIC and the VM must be in the same region. Resource group does not matter.
- If the old VM had accelerated networking enabled, the new VM size must support it or the attach fails.
- If you later switch the NIC from a `data` source back to a `resource` block in Terraform, use `terraform import` rather than letting Terraform recreate it.
