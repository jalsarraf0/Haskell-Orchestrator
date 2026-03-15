# Capability Matrix — Haskell Orchestrator

This matrix defines the formal ownership and availability of every product
capability across the three editions.  It is the human-readable form of the
machine-checkable manifest at `config/capability-contract.yaml`.

## How to Read This Matrix

- **Owner** — the tier that implements and owns the capability
- **Community / Business / Enterprise** — which editions expose it
- Checkmark means the capability is available in that edition
- Dash means the capability is explicitly excluded from that edition

---

## Scanning

| ID | Capability | Owner | Community | Business | Enterprise |
|----|-----------|-------|:---------:|:--------:|:----------:|
| CAP-0001 | Single-repo scanning | Community | Yes | Yes | Yes |
| CAP-0002 | Multi-repo batch scanning | Business | — | Yes | Yes |
| CAP-0003 | Organisation-wide scanning | Enterprise | — | — | Yes |

## Validation

| ID | Capability | Owner | Community | Business | Enterprise |
|----|-----------|-------|:---------:|:--------:|:----------:|
| CAP-0010 | Structural validation | Community | Yes | Yes | Yes |

## Policy

| ID | Capability | Owner | Community | Business | Enterprise |
|----|-----------|-------|:---------:|:--------:|:----------:|
| CAP-0020 | Standard policy pack (10 rules) | Community | Yes | Yes | Yes |
| CAP-0021 | Team policy pack (+4 rules) | Business | — | Yes | Yes |
| CAP-0022 | Governance policy engine | Enterprise | — | — | Yes |

## Diff & Remediation

| ID | Capability | Owner | Community | Business | Enterprise |
|----|-----------|-------|:---------:|:--------:|:----------:|
| CAP-0030 | Diff generation | Community | Yes | Yes | Yes |
| CAP-0040 | Basic remediation planning | Community | Yes | Yes | Yes |
| CAP-0041 | Prioritised remediation + effort | Business | — | Yes | Yes |

## Reporting & Output

| ID | Capability | Owner | Community | Business | Enterprise |
|----|-----------|-------|:---------:|:--------:|:----------:|
| CAP-0050 | Text and JSON output | Community | Yes | Yes | Yes |
| CAP-0051 | HTML and CSV reports | Business | — | Yes | Yes |
| CAP-0052 | Summary statistics | Business | — | Yes | Yes |

## Governance

| ID | Capability | Owner | Community | Business | Enterprise |
|----|-----------|-------|:---------:|:--------:|:----------:|
| CAP-0060 | Governance enforcement | Enterprise | — | — | Yes |
| CAP-0061 | Policy scoping | Enterprise | — | — | Yes |

## Audit

| ID | Capability | Owner | Community | Business | Enterprise |
|----|-----------|-------|:---------:|:--------:|:----------:|
| CAP-0070 | Immutable audit trail | Enterprise | — | — | Yes |
| CAP-0071 | Audit log export | Enterprise | — | — | Yes |

## Compliance

| ID | Capability | Owner | Community | Business | Enterprise |
|----|-----------|-------|:---------:|:--------:|:----------:|
| CAP-0080 | Compliance framework mapping | Enterprise | — | — | Yes |
| CAP-0081 | Compliance artifact generation | Enterprise | — | — | Yes |

## Administration

| ID | Capability | Owner | Community | Business | Enterprise |
|----|-----------|-------|:---------:|:--------:|:----------:|
| CAP-0090 | Administrative workflows | Enterprise | — | — | Yes |

## Demo & Evaluation

| ID | Capability | Owner | Community | Business | Enterprise |
|----|-----------|-------|:---------:|:--------:|:----------:|
| CAP-0100 | Demo mode | Community | Yes | Yes | Yes |

---

## Summary by Tier

| Tier | Total Capabilities | Owned | Inherited |
|------|:-----------------:|:-----:|:---------:|
| Community | 8 | 8 | 0 |
| Business | 13 | 5 | 8 |
| Enterprise | 20 | 7 | 13 |

## What Each Tier Does NOT Include

### Community Does NOT Include

- Multi-repo batch scanning (CAP-0002) → Business
- Organisation-wide scanning (CAP-0003) → Enterprise
- Team policy pack (CAP-0021) → Business
- Governance policy engine (CAP-0022) → Enterprise
- Prioritised remediation (CAP-0041) → Business
- HTML/CSV reports (CAP-0051) → Business
- Summary statistics (CAP-0052) → Business
- Governance enforcement (CAP-0060) → Enterprise
- Policy scoping (CAP-0061) → Enterprise
- Audit trail (CAP-0070, CAP-0071) → Enterprise
- Compliance mapping (CAP-0080, CAP-0081) → Enterprise
- Administrative workflows (CAP-0090) → Enterprise

### Business Does NOT Include

- Organisation-wide scanning (CAP-0003) → Enterprise
- Governance policy engine (CAP-0022) → Enterprise
- Governance enforcement (CAP-0060) → Enterprise
- Policy scoping (CAP-0061) → Enterprise
- Audit trail (CAP-0070, CAP-0071) → Enterprise
- Compliance mapping (CAP-0080, CAP-0081) → Enterprise
- Administrative workflows (CAP-0090) → Enterprise

### Enterprise Includes Everything

Enterprise is the superset tier.  All 20 capabilities are available.
