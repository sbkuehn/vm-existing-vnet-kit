#!/usr/bin/env bash
# deploy-arm.sh
# Author: Shannon Eldridge-Kuehn
# Created: 2026-09-04
# Usage: ./deploy-arm.sh <target-resource-group> [parameters-file]
# Runs what-if, asks for confirmation, then deploys.
set -euo pipefail
RG="${1:?target resource group required}"
cd "$(dirname "$0")/.."
PARAMS="${2:-arm/vm-existing-vnet.parameters.json}"
az deployment group what-if -g "$RG" --template-file arm/vm-existing-vnet.json --parameters "@${PARAMS}"
read -r -p "Proceed with deployment? [y/N] " ans
[[ "$ans" =~ ^[Yy]$ ]] || exit 0
az deployment group create -g "$RG" --template-file arm/vm-existing-vnet.json --parameters "@${PARAMS}" -o table
