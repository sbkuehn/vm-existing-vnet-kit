# providers.tf
# Author: Shannon Eldridge-Kuehn
# Created: 2026-09-04
# Repo:   https://github.com/sbkuehn/vm-existing-vnet-kit

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Default provider: the subscription where the VM will live.
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Aliased provider: the subscription that owns the existing vNet.
# When network_subscription_id is null this resolves to the same
# subscription as the default provider and the alias is a no-op.
provider "azurerm" {
  alias           = "network"
  features {}
  subscription_id = coalesce(var.network_subscription_id, var.subscription_id)
}
