# Permissions

Author: Shannon Eldridge-Kuehn
Created: 2026-09-04

Deploying a VM into a subnet you do not own is the one place where "Contributor on my resource group" is not enough. This page lists what the deploying identity actually needs.

## On the target (workload) resource group

The identity creating the VM and NIC needs the usual write permissions. Any of these work:

- `Contributor`
- `Virtual Machine Contributor` plus `Network Contributor`
- A custom role with `Microsoft.Compute/virtualMachines/write`, `Microsoft.Compute/disks/write`, and `Microsoft.Network/networkInterfaces/write`

## On the existing subnet

This is the one that trips people up. Creating a NIC in a subnet is a **join** operation on that subnet, and it is authorized against the subnet's resource ID, not the NIC's. The identity needs:

```
Microsoft.Network/virtualNetworks/subnets/join/action
```

The built-in `Network Contributor` role includes it, but that role is far too broad to hand out on a hub vNet. The cleaner option is a custom role scoped to the vNet or the individual subnet:

```json
{
  "Name": "Subnet Joiner",
  "Description": "Allows attaching NICs to subnets without any other network write access.",
  "Actions": [
    "Microsoft.Network/virtualNetworks/read",
    "Microsoft.Network/virtualNetworks/subnets/read",
    "Microsoft.Network/virtualNetworks/subnets/join/action"
  ],
  "NotActions": [],
  "AssignableScopes": [
    "/subscriptions/<subscription-id>/resourceGroups/rg-network-prod"
  ]
}
```

Create and assign it:

```bash
az role definition create --role-definition subnet-joiner.json

az role assignment create \
  --assignee <object-id-or-upn> \
  --role "Subnet Joiner" \
  --scope "/subscriptions/<sub>/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-hub-prod/subnets/snet-servers"
```

## The error you will see without it

```
LinkedAuthorizationFailed: The client '...' with object id '...' has permission to perform action
'Microsoft.Network/networkInterfaces/write' on scope '.../rg-app-prod/providers/Microsoft.Network/networkInterfaces/nic-vm-app-01';
however, it does not have permission to perform action 'Microsoft.Network/virtualNetworks/subnets/join/action'
on the linked scope '.../rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-hub-prod/subnets/snet-servers'
```

`LinkedAuthorizationFailed` is the giveaway. The write on the NIC was allowed; the join on the subnet was not. `scripts/preflight.sh` checks for this before you deploy.

## Static IPs

Assigning a static private IP needs no extra permission, but the address must fall inside the subnet prefix and avoid the five addresses Azure reserves per subnet (the first four and the last). The preflight script prints the prefix so you can sanity check.
