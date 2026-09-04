#!/usr/bin/env bash
# deploy-bicep.sh
# Author: Shannon Eldridge-Kuehn
# Created: 2026-09-04
# Usage: VM_ADMIN_PASSWORD=... ./deploy-bicep.sh <target-resource-group> [bicepparam-file]
# Runs what-if, asks for confirmation, then deploys.
set -euo pipefail
RG="${1:?target resource group required}"
: "${VM_ADMIN_PASSWORD:?set VM_ADMIN_PASSWORD in the environment}"
cd "$(dirname "$0")/.."
PARAMS="${2:-bicep/vm-existing-vnet.bicepparam}"
az deployment group what-if -g "$RG" --parameters "$PARAMS"
read -r -p "Proceed with deployment? [y/N] " ans
[[ "$ans" =~ ^[Yy]$ ]] || exit 0
az deployment group create -g "$RG" --parameters "$PARAMS" -o table
