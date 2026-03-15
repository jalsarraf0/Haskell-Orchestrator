# Capability Contract — Haskell Orchestrator

## Purpose

This document defines the formal rules governing which capabilities belong
to which edition.  These rules are enforced by:

- The machine-readable manifest at `config/capability-contract.yaml`
- The validation script at `scripts/check-capability-contract.sh`
- The CI workflow (contract-check job in `ci.yml`)

Changes to capability ownership require updating all three.

## Contract Rules

### Rule 1: Module Isolation

No tier may import modules from a higher tier:
- Community must not import `OrchestratorBusiness.*` or `OrchestratorEnterprise.*`
- Business must not import `OrchestratorEnterprise.*`

### Rule 2: Feature File Isolation

Capabilities forbidden in a tier must not have corresponding source files:
- Community must not contain `Batch.hs`, `Report.hs`, `Governance.hs`,
  `Audit.hs`, `Compliance.hs`, or `Admin.hs`
- Business must not contain `Governance.hs`, `Audit.hs`, `Compliance.hs`,
  or `Admin.hs`

### Rule 3: CLI Surface Consistency

CLI commands must match the capability contract:
- Community CLI must not expose `batch`, `report`, `stats`, `governance`,
  `audit`, `compliance`, or `admin` commands
- Business CLI must not expose `governance`, `audit`, `compliance`, or
  `admin` commands

### Rule 4: Documentation Consistency

Documentation must not claim capabilities that are forbidden in a tier:
- Community README must not claim multi-repo batch scanning, HTML reports,
  governance, audit, or compliance capabilities
- Business README must not claim governance, audit, or compliance

### Rule 5: Attribution Isolation

No tracked file in any tier may contain AI attribution markers.
This is checked by both the release gate and the contract validation scripts.

## Governance

The capability contract is maintained by the project maintainer.  Changes
to the contract require:

1. Update `config/capability-contract.yaml`
2. Update `docs/capability-matrix.md`
3. Update affected tier README files
4. Run `scripts/check-capability-contract.sh` to validate
5. Ensure CI passes the contract-check job

## Versioning

The capability contract is versioned alongside the product.  Breaking
changes to the contract (moving capabilities between tiers) require a
minor version bump in the affected tiers.
