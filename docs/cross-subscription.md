# Cross-Subscription Deployments

Author: Shannon Eldridge-Kuehn
Created: 2026-09-04

The default examples assume the vNet lives in a different resource group but the same subscription as the VM. When the network is in its own subscription, which is common in landing zone designs with a dedicated connectivity subscription, each tool needs one extra hint.

## ARM Template

`resourceId()` accepts a subscription ID as its first argument. The template exposes this as `existingVnetSubscriptionId`, defaulting to the deployment subscription:

```json
"subnetId": "[resourceId(parameters('existingVnetSubscriptionId'), parameters('existingVnetResourceGroup'), 'Microsoft.Network/virtualNetworks/subnets', parameters('existingVnetName'), parameters('existingSubnetName'))]"
```

Pass the connectivity subscription ID at deploy time:

```bash
az deployment group create -g rg-app-prod \
  --template-file arm/vm-existing-vnet.json \
  --parameters @arm/vm-existing-vnet.parameters.json \
  --parameters existingVnetSubscriptionId=<connectivity-sub-id>
```

## Bicep

`resourceGroup()` takes an optional subscription ID before the resource group name. The template already does this:

```bicep
resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: existingVnetName
  scope: resourceGroup(existingVnetSubscriptionId, existingVnetResourceGroup)
}
```

Same deploy-time override as ARM: `--parameters existingVnetSubscriptionId=<connectivity-sub-id>`.

## Terraform

A Terraform provider is bound to a single subscription, so the configuration declares a second, aliased provider for the network subscription and points the subnet data source at it:

```hcl
provider "azurerm" {
  alias           = "network"
  features {}
  subscription_id = coalesce(var.network_subscription_id, var.subscription_id)
}

data "azurerm_subnet" "existing" {
  provider = azurerm.network
  ...
}
```

Set `network_subscription_id` in `terraform.tfvars`. When it is left null the alias resolves to the same subscription as the default provider, so single-subscription users do not need to change anything.

## Permissions

The join permission described in [permissions.md](permissions.md) is still required, now on a subnet in another subscription. The deploying identity (or the service principal in your pipeline) needs a role assignment in the connectivity subscription, not just the workload subscription.
