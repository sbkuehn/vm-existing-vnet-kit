# Virtual Machine in an Existing VNet

Deploy an Azure VM into a virtual network that already exists, written three ways: ARM Template, Bicep, and Terraform.

Companion repository for the Cloudy Musings post **Deploying a VM into an Existing Virtual Network: ARM, Bicep, and Terraform**.

> Author: Shannon Eldridge-Kuehn
> Created: 2026-09-04
> License: MIT

## Why this repo exists

Almost every VM quickstart on the internet creates a brand new vNet, a brand new subnet, a brand new NIC, and then the VM. That is fine for a demo and wrong for nearly every real environment, where the network already exists, is owned by someone else, and is peered, routed, and secured in ways you do not want to recreate.

The fix is small but easy to miss: stop creating the network and look it up instead. The NIC is still new (every VM needs one), but it points at a subnet the template references rather than one it built.

| Tool | Mechanism | Where it lives |
|---|---|---|
| ARM Template | `resourceId()` | `arm/vm-existing-vnet.json` |
| Bicep | `existing` keyword | `bicep/vm-existing-vnet.bicep` |
| Terraform | `data "azurerm_subnet"` | `terraform/main.tf` |

All three templates are functionally identical and produce the same two resources: one NIC and one Windows Server 2022 VM, with no public IP, attached to an existing subnet that may live in a different resource group or subscription.

## Repository layout

```
vm-existing-vnet-kit/
  arm/
    vm-existing-vnet.json              ARM Template
    vm-existing-vnet.parameters.json   Example parameters (Key Vault ref for password)
  bicep/
    vm-existing-vnet.bicep             Bicep template
    vm-existing-vnet.bicepparam        Example parameters
  terraform/
    providers.tf                       azurerm ~> 4.0, with an aliased network provider
    variables.tf
    main.tf                            Data sources plus NIC and VM
    outputs.tf
    terraform.tfvars.example
  scripts/
    preflight.sh                       Checks vNet, subnet, delegation, free IPs, join permission
    deploy-arm.sh                      what-if, confirm, deploy
    deploy-bicep.sh                    what-if, confirm, deploy
  docs/
    permissions.md                     The subnets/join/action permission and a custom role
    cross-subscription.md              Referencing a vNet in another subscription
    existing-nic.md                    Attaching a VM to a pre-existing NIC
  CHANGELOG.md
  LICENSE
```

## Prerequisites

- An existing virtual network with at least one subnet that is not delegated to a PaaS service
- An existing resource group for the VM (the templates do not create it)
- Azure CLI 2.60 or later with Bicep installed (`az bicep install`) for the ARM and Bicep paths
- Terraform 1.6 or later for the Terraform path
- `jq` for `scripts/preflight.sh`
- Permission to join the target subnet. See [docs/permissions.md](docs/permissions.md).

If you do not have a vNet yet, any of these will get you one:

- [Azure Portal](https://learn.microsoft.com/azure/virtual-network/quick-create-portal)
- [PowerShell](https://learn.microsoft.com/azure/virtual-network/quick-create-powershell)
- [Azure CLI](https://learn.microsoft.com/azure/virtual-network/quick-create-cli)
- [ARM Template](https://learn.microsoft.com/azure/virtual-network/quick-create-template)

## Default names

Every example assumes the following. Override them with parameters or variables; nothing is hardcoded.

| Item | Default |
|---|---|
| Network resource group | `rg-network-prod` |
| Virtual network | `vnet-hub-prod` |
| Subnet | `snet-servers` |
| Workload resource group | `rg-app-prod` |
| VM name | `vm-app-01` |
| VM size | `Standard_D2s_v5` |

## Quick start

Run the preflight first. It catches the failures that account for most wasted deployment attempts: wrong subnet name, delegated subnet, exhausted address space, and missing join permission.

```bash
./scripts/preflight.sh rg-network-prod vnet-hub-prod snet-servers
```

### ARM

```bash
az deployment group create \
  --resource-group rg-app-prod \
  --template-file arm/vm-existing-vnet.json \
  --parameters @arm/vm-existing-vnet.parameters.json \
  --parameters adminPassword='<password>'
```

The example parameters file references a Key Vault secret for `adminPassword`. Either update the vault ID or pass the value inline as shown above, which overrides the file.

### Bicep

```bash
export VM_ADMIN_PASSWORD='<password>'
az deployment group create \
  --resource-group rg-app-prod \
  --parameters bicep/vm-existing-vnet.bicepparam
```

To see what Bicep does with the `existing` keyword, run `az bicep build --file bicep/vm-existing-vnet.bicep` and compare the generated JSON to `arm/vm-existing-vnet.json`. The same `resourceId()` call is there; Bicep just wrote it for you.

### Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your subscription ID and names
export TF_VAR_admin_password='<password>'
terraform init
terraform plan
terraform apply
```

Terraform fails at `plan` if the subnet does not exist, which is a nicer failure mode than ARM accepting a bad resource ID and failing partway through `create`.

## Parameters and variables

| ARM / Bicep | Terraform | Purpose |
|---|---|---|
| `vmName` | `vm_name` | VM and computer name, 15 characters max |
| `vmSize` | `vm_size` | VM SKU |
| `adminUsername` | `admin_username` | Local admin |
| `adminPassword` | `admin_password` | Local admin password (secure) |
| `existingVnetSubscriptionId` | `network_subscription_id` | Only set when the vNet is in another subscription |
| `existingVnetResourceGroup` | `existing_vnet_resource_group` | Resource group that owns the vNet |
| `existingVnetName` | `existing_vnet_name` | vNet name |
| `existingSubnetName` | `existing_subnet_name` | Subnet name |
| `privateIpAllocationMethod` + `privateIpAddress` | `private_ip_address` | Leave default for dynamic; set for static |
| `location` | (from resource group) | Must match the vNet region |
| `tags` | `tags` | Applied to VM and NIC |

## Outputs

All three return the VM ID, NIC ID, the subnet ID that was resolved, and the private IP assigned.

## Design choices

- **No public IP.** If you are deploying into an existing hub-and-spoke network you already have Bastion, a jump host, or a VPN. A public IP on a workload VM is a CSPM finding waiting to happen. Add one deliberately if you need it.
- **No NSG on the NIC.** Subnet-level NSGs are the norm in landing zones. A NIC-level NSG here would create a second rule set to reason about.
- **Windows Server 2022 Azure Edition, platform patching, boot diagnostics on.** Reasonable defaults that you can change in one place.
- **Separate resource groups for network and workload.** The examples deliberately split these because that is how most organizations are set up, and it forces the cross-resource-group reference to be handled correctly.

## Further reading

- [docs/permissions.md](docs/permissions.md) for the `subnets/join/action` permission and a least-privilege custom role
- [docs/cross-subscription.md](docs/cross-subscription.md) for when the vNet is in a connectivity subscription
- [docs/existing-nic.md](docs/existing-nic.md) for attaching to a pre-created NIC
- [Bicep existing resources](https://learn.microsoft.com/azure/azure-resource-manager/bicep/existing-resource)
- [ARM resourceId() function](https://learn.microsoft.com/azure/azure-resource-manager/templates/template-functions-resource#resourceid)
- [Terraform azurerm_subnet data source](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet)
- [sbkuehn/replicaDcs](https://github.com/sbkuehn/replicaDcs), where this same pattern is used for domain controllers

## Contributing

Issues and pull requests are welcome. If you add a fourth tool (Pulumi, Crossplane, whatever comes next), keep the same parameter names and the same two-resource output so the examples stay comparable.

## License

MIT. See [LICENSE](LICENSE).

Copyright (c) 2026 Shannon Eldridge-Kuehn
