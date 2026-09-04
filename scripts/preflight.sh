#!/usr/bin/env bash
# preflight.sh
# Author: Shannon Eldridge-Kuehn
# Created: 2026-09-04
# Repo:   https://github.com/sbkuehn/vm-existing-vnet-kit
#
# Verifies the prerequisites for deploying a VM into an existing subnet before
# you burn a deployment attempt finding out the hard way:
#   1. The vNet exists
#   2. The subnet exists inside it
#   3. The subnet is not delegated to a PaaS service
#   4. The subnet has free addresses
#   5. The signed-in identity holds subnets/join/action on the subnet
#
# Usage:
#   ./preflight.sh <vnet-resource-group> <vnet-name> <subnet-name> [subscription-id]

set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <vnet-resource-group> <vnet-name> <subnet-name> [subscription-id]" >&2
  exit 2
fi

RG="$1"
VNET="$2"
SUBNET="$3"
SUB="${4:-}"

SUB_ARGS=()
if [[ -n "$SUB" ]]; then
  SUB_ARGS=(--subscription "$SUB")
fi

FAILED=0
pass() { printf '  [PASS] %s\n' "$1"; }
fail() { printf '  [FAIL] %s\n' "$1"; FAILED=1; }

echo "Preflight: ${VNET}/${SUBNET} in ${RG}${SUB:+ (subscription ${SUB})}"

# 1. vNet exists
if az network vnet show "${SUB_ARGS[@]}" -g "$RG" -n "$VNET" -o none 2>/dev/null; then
  pass "vNet ${VNET} exists"
else
  fail "vNet ${VNET} not found in ${RG}"
  echo "Preflight failed."
  exit 1
fi

# 2. Subnet exists
SUBNET_JSON=$(az network vnet subnet show "${SUB_ARGS[@]}" -g "$RG" --vnet-name "$VNET" -n "$SUBNET" -o json 2>/dev/null || true)
if [[ -z "$SUBNET_JSON" ]]; then
  fail "subnet ${SUBNET} not found in ${VNET}"
  echo "Preflight failed."
  exit 1
fi
pass "subnet ${SUBNET} exists"
SUBNET_ID=$(echo "$SUBNET_JSON" | jq -r '.id')
PREFIX=$(echo "$SUBNET_JSON" | jq -r '.addressPrefix // .addressPrefixes[0]')

# 3. Not delegated
DELEG=$(echo "$SUBNET_JSON" | jq -r '.delegations[0].serviceName // empty')
if [[ -n "$DELEG" ]]; then
  fail "subnet is delegated to ${DELEG}; VMs cannot be placed here"
else
  pass "subnet is not delegated"
fi

# 4. Free addresses
AVAIL=$(az network vnet subnet list-available-ips "${SUB_ARGS[@]}" -g "$RG" --vnet-name "$VNET" -n "$SUBNET" -o tsv 2>/dev/null | wc -l | tr -d ' ')
if [[ "$AVAIL" -gt 0 ]]; then
  pass "subnet ${PREFIX} has available addresses"
else
  fail "subnet ${PREFIX} reports no available addresses"
fi

# 5. Join permission
ME=$(az ad signed-in-user show --query userPrincipalName -o tsv 2>/dev/null || az account show --query user.name -o tsv)
if az rest --method post \
  --url "https://management.azure.com${SUBNET_ID}/providers/Microsoft.Authorization/permissions?api-version=2022-04-01" \
  -o json 2>/dev/null | jq -e '
    [.value[].actions[]] as $a
    | ($a | index("*")) != null
      or ($a | index("Microsoft.Network/*")) != null
      or ($a | index("Microsoft.Network/virtualNetworks/*")) != null
      or ($a | index("Microsoft.Network/virtualNetworks/subnets/*")) != null
      or ($a | index("Microsoft.Network/virtualNetworks/subnets/join/action")) != null' >/dev/null; then
  pass "caller (${ME}) has subnets/join/action"
else
  fail "caller (${ME}) does not appear to hold Microsoft.Network/virtualNetworks/subnets/join/action"
fi

echo
if [[ "$FAILED" -eq 0 ]]; then
  echo "Preflight passed. Subnet ID:"
  echo "  ${SUBNET_ID}"
else
  echo "Preflight failed. Fix the items above before deploying."
  exit 1
fi
