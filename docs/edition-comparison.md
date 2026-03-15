# Haskell Orchestrator — Edition Comparison

Author: Jamal Al-Sarraf

---

## Feature Matrix

| Feature | Community | Business | Enterprise |
|---|:---:|:---:|:---:|
| **Scanning and Analysis** | | | |
| GitHub Actions YAML parsing into typed domain model | x | x | x |
| Single-repository workflow scanning | x | x | x |
| Structural validation (empty jobs, dangling needs, duplicate IDs) | x | x | x |
| Diff view of current issues | x | x | x |
| Remediation plan generation | x | x | x |
| Demo mode with synthetic fixtures | x | x | x |
| Doctor (environment diagnostics) | x | x | x |
| Rule explanation (`explain RULE_ID`) | x | x | x |
| Configuration init and verify | x | x | x |
| **Policy Engine** | | | |
| Standard policy pack (10 rules) | x | x | x |
| PERM-001: Permissions Required | x | x | x |
| PERM-002: Broad Permissions | x | x | x |
| SEC-001: Unpinned Actions | x | x | x |
| SEC-002: Secret in Run Step | x | x | x |
| RUN-001: Self-Hosted Runner Detection | x | x | x |
| CONC-001: Missing Concurrency | x | x | x |
| RES-001: Missing Timeout | x | x | x |
| NAME-001: Workflow Naming | x | x | x |
| NAME-002: Job Naming Convention | x | x | x |
| TRIG-001: Wildcard Triggers | x | x | x |
| Team naming convention rules | | x | x |
| Branch protection pattern checks | | x | x |
| Required reviewer gate detection | | x | x |
| Dependency update automation detection | | x | x |
| **Output Formats** | | | |
| Plain text output | x | x | x |
| JSON output | x | x | x |
| HTML report generation | | x | x |
| CSV export | | x | x |
| Summary statistics | | x | x |
| **Multi-Repository** | | | |
| Multi-repo batch scanning | | x | x |
| Bounded parallelism (1-32 workers) | | x | x |
| Batch stop-on-error control | | x | x |
| **Remediation** | | | |
| Basic remediation plan | x | x | x |
| Prioritized remediation with effort estimates | | x | x |
| Quick-fix vs. comprehensive strategies | | x | x |
| Plan merging and deduplication | | x | x |
| **Governance** | | | |
| Organisation-wide governance policies (5 policies) | | | x |
| Typed enforcement levels (Advisory/Mandatory/Blocking) | | | x |
| Policy scoping (all repos, pattern match, specific repos) | | | x |
| Dry-run mode for governance operations | | | x |
| **Audit** | | | |
| Immutable audit trail | | | x |
| Audit log querying (actor, action, target, time, severity) | | | x |
| Audit log export (JSON, CSV) | | | x |
| **Compliance** | | | |
| SOC 2 Type II compliance mapping | | | x |
| HIPAA Security Rule compliance mapping | | | x |
| Per-repository compliance scoring | | | x |
| Compliance artifact generation | | | x |
| **Administration** | | | |
| Administrative workflows (enforce, scan, export) | | | x |
| Full organisation scan | | | x |
| Compliance artifact export | | | x |
| **Licensing** | | | |
| License | MIT (free) | Private license | Private license |
| Source availability | Public | Private | Private |

---

## Who Is This For?

### Community Edition

- Individual developers maintaining personal or small open-source projects
- Teams evaluating Haskell Orchestrator before purchasing
- Contributors who want to inspect, build, and extend the core engine
- Anyone who needs single-repository workflow scanning and validation
- CI pipelines that gate on workflow hygiene for a single repository

Community is the right starting point if you manage fewer than five repositories
and do not need consolidated reporting or governance enforcement.

### Business Edition

- Engineering teams managing 5 to 50 repositories
- Platform engineering and DevOps teams enforcing CI/CD standards across a codebase
- Teams that need to produce HTML or CSV reports for stakeholders, managers, or audits
- Organisations requiring batch scanning across multiple repositories in a single run
- Teams that want prioritized remediation plans with effort and cost estimates

Business is the right choice when you outgrow single-repo scanning and need
cross-repository visibility, structured reports, and actionable remediation
priorities.

### Enterprise Edition

- Platform engineering teams managing 50+ repositories at organisation scale
- Security and compliance teams that must map CI/CD controls to SOC 2, HIPAA,
  or other frameworks
- Organisations that require immutable audit trails for governance decisions
- Administrators who need typed enforcement levels (Advisory, Mandatory, Blocking)
  with scoped policy application across the organisation
- Regulated industries where compliance artifact generation is a requirement

Enterprise is the right choice when governance, audit, and compliance are
first-class requirements, not afterthoughts.

---

## What Is NOT Included?

### Community Edition Does Not Include

- Multi-repository batch scanning
- HTML or CSV report generation
- Summary statistics dashboards
- Team-specific policy rules (naming conventions, branch protection, reviewer gates, dependency update detection)
- Prioritized remediation with effort estimates
- Quick-fix vs. comprehensive remediation strategies
- Plan merging and deduplication
- Organisation-wide governance policies
- Immutable audit trails
- Compliance framework mapping
- Administrative workflows

### Business Edition Does Not Include

- Organisation-wide governance policies with enforcement levels
- Policy scoping by repository pattern or specific repository list
- Immutable audit trail with queryable log
- SOC 2 Type II compliance mapping
- HIPAA Security Rule compliance mapping
- Per-repository compliance scoring
- Compliance artifact generation
- Administrative workflows (org-wide enforce, org-wide scan, compliance export)
- Dry-run mode for governance operations

### Enterprise Edition

Enterprise includes all features from all tiers. There are no features withheld
from this edition.

---

## Decision Tree: Which Edition Should I Use?

```
Start
  |
  v
Do you scan more than one repository in a single workflow?
  |
  +-- No --> Do you need HTML/CSV reports or effort-based remediation plans?
  |            |
  |            +-- No --> COMMUNITY
  |            +-- Yes -> BUSINESS
  |
  +-- Yes --> Do you need org-wide governance, audit trails, or compliance mapping?
               |
               +-- No --> BUSINESS
               +-- Yes -> ENTERPRISE
```

Additional decision factors:

| If you need... | Choose |
|---|---|
| A free, open-source tool for one repo | Community |
| Batch scanning across a team's repos | Business |
| HTML reports for leadership or stakeholders | Business |
| Prioritized remediation with effort estimates | Business |
| SOC 2 or HIPAA compliance mapping | Enterprise |
| Immutable audit trails | Enterprise |
| Typed policy enforcement (Advisory/Mandatory/Blocking) | Enterprise |
| Compliance artifact generation for auditors | Enterprise |

---

## Upgrade Path

### Community to Business

1. Obtain a Business license.
2. Clone the Business repository alongside the existing Community checkout.
3. The Business binary (`orchestrator-business`) is a separate executable that
   depends on the Community library. Your existing `.orchestrator.yml`
   configuration is fully compatible.
4. Existing scan targets, exclusion rules, and disabled rule lists carry
   forward without changes.
5. New Business-tier policy rules are automatically included in the full
   policy pack. You can selectively disable them in configuration if needed.
6. Begin using `batch`, `report`, `stats`, and `plan --quick` commands.

### Business to Enterprise

1. Obtain an Enterprise license.
2. Clone the Enterprise repository alongside the existing Community checkout.
3. The Enterprise binary (`orchestrator-enterprise`) extends the Community
   library with governance, audit, and compliance modules.
4. Existing configuration carries forward. Enterprise adds `--org` scoping and
   governance-specific configuration.
5. Define your organisation's governance policies using the typed policy
   system (enforcement levels, scoping rules).
6. Begin using `governance`, `audit`, `compliance`, and `admin` commands.

### Downgrade

Downgrading is straightforward because each edition is a separate binary.
Simply stop using the higher-tier binary and continue with the lower-tier
one. No data migration is needed since the tool does not persist state across
sessions (Enterprise audit logs are in-memory and exported on demand).

---

## Pricing Model

| Edition | Price | License |
|---|---|---|
| Community | Free | MIT (open source) |
| Business | Contact for pricing | Private license, all rights reserved |
| Enterprise | Contact for pricing | Private license, all rights reserved |

Community is and will remain free and open source. Business and Enterprise
are proprietary products with private licensing.
