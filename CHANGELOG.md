# Changelog

All notable changes to this repository are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.0] - 2026-09-04

### Added
- ARM Template (`arm/`) that deploys a Windows Server 2022 VM into an existing subnet using `resourceId()`
- Bicep template (`bicep/`) using the `existing` keyword for the vNet and subnet
- Terraform configuration (`terraform/`) using the `azurerm_subnet` data source
- Parameter and variable example files for each tool
- Preflight script (`scripts/preflight.sh`) that verifies the target subnet exists and the caller can join it
- Documentation covering cross-subscription references, required permissions, and reusing an existing NIC
- MIT license

[1.0.0]: https://github.com/sbkuehn/vm-existing-vnet-kit/releases/tag/v1.0.0
