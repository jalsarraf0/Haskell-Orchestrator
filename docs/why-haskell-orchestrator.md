# Why Haskell Orchestrator?

Author: Jamal Al-Sarraf

---

## The Problem

As organisations grow, GitHub Actions workflows accumulate technical debt:

- Permissions become overly broad because no one remembers to scope them down.
- Third-party actions drift to unpinned tag references, creating supply-chain risk.
- Timeouts disappear, leading to runaway jobs that consume runner minutes.
- Naming conventions break down across teams, making the Actions tab
  unreadable.
- Concurrency controls are absent, causing duplicate PR builds.
- Security hygiene degrades gradually, unnoticed until an incident.

Catching these issues manually across dozens or hundreds of repositories is
impractical. Reviewing every workflow file in every pull request for
structural and policy compliance does not scale.

---

## What Exists Today

### Generic YAML Linters (yamllint, actionlint)

Tools like `yamllint` and `actionlint` verify YAML syntax and some
GitHub Actions-specific schema rules. They answer the question: "Is this
valid YAML?" and "Does this conform to the Actions schema?"

They do not answer:
- Are permissions appropriately scoped?
- Are third-party actions pinned to commit SHAs?
- Do all jobs have timeouts?
- Do naming conventions follow team standards?
- What is the remediation priority across many findings?
- What would a remediation plan look like?

Haskell Orchestrator is not a YAML linter. It parses workflow YAML into
a typed domain model and evaluates that model against a policy engine.
The output is not "line 42 has a syntax error" but "this workflow grants
write-all permissions (PERM-002, Error severity) — add fine-grained
permissions instead."

### GitHub-Native Security Features (Dependabot, Code Scanning)

GitHub provides Dependabot for dependency updates and code scanning
(CodeQL) for vulnerability detection in application code. These are
valuable tools, but they operate on application source code, not on
the CI/CD pipeline definitions themselves.

Dependabot does not tell you that your workflow uses an unpinned
third-party action. CodeQL does not tell you that your CI job lacks a
timeout. Neither tool produces a remediation plan for workflow hygiene.

Haskell Orchestrator operates on the workflows themselves — the `.yml`
files in `.github/workflows/` — treating them as first-class artifacts
that deserve the same rigour as application code.

### Security-Only CI Tools

Some tools focus exclusively on secrets detection or vulnerability scanning
within CI pipelines. They answer: "Is there a leaked secret?" or "Is this
dependency vulnerable?"

Haskell Orchestrator covers security concerns (unpinned actions, secrets
in run steps, broad permissions) but also addresses structural quality,
naming conventions, concurrency hygiene, runner configuration, and
overall workflow standardisation. Security is one category among several,
not the only lens.

### Reusable Workflow Wrappers

Some teams build reusable workflow templates and require all repositories
to use them. This works for new repositories but does not address:
- Existing repositories that predate the template
- Repositories that need customisation beyond the template
- Detecting drift from the template over time
- Producing reports on compliance across the organisation

Haskell Orchestrator scans actual workflow files as they exist on disk,
regardless of how they were created. It detects what is, not what should be.

---

## What Makes Haskell Orchestrator Different

### Typed Domain Model

Workflow files are not treated as raw YAML or string blobs. They are parsed
into a strongly typed Haskell data model:

- `Workflow` — name, filename, triggers, jobs, permissions, concurrency,
  environment
- `Job` — ID, runner spec, steps, permissions, dependencies, timeout,
  concurrency
- `Step` — action uses, shell commands, environment, conditionals
- `Permissions` — blanket level or fine-grained scope map
- `WorkflowTrigger` — events, cron schedules, manual dispatch
- `RunnerSpec` — standard, matrix, or custom label

This means policy rules operate on structured, type-checked data, not on
string matching against raw YAML. A rule that checks for missing permissions
queries `wfPermissions :: Maybe Permissions`, not `grep -q "permissions:"`.

### Policy Engine

Policy rules are typed functions: `Workflow -> [Finding]`. Each finding
carries:
- Severity (Info, Warning, Error, Critical)
- Category (Permissions, Security, Runners, Concurrency, Structure, Naming,
  Triggers)
- Rule ID (e.g., SEC-001, PERM-002)
- Human-readable message explaining the issue
- File path where the issue was found
- Remediation suggestion

Rules are grouped into named packs. The standard pack ships with 10 rules
covering the most common workflow issues. Rules can be disabled selectively
in configuration. Minimum severity thresholds filter out noise.

### Drift Detection

The diff command shows current issues in a format optimised for detecting
what has changed or degraded. This enables:
- Periodic drift detection in CI (run weekly, compare findings)
- Pull request gates (fail if new Error-severity findings appear)
- Trend tracking over time (are we improving or degrading?)

### Standardisation

The tool enforces that workflows follow organisational standards:
- Naming conventions (kebab-case job IDs, descriptive workflow names)
- Structural requirements (explicit permissions, timeouts on all jobs)
- Security hygiene (pinned actions, no inline secrets)

These are not aspirational guidelines — they are machine-checkable rules
with clear severity levels and specific remediation suggestions.

### Remediation Planning

The plan command produces a structured, prioritised remediation plan:
- What to fix
- Why to fix it
- How to fix it
- Which rule triggered the finding

This turns "we have 47 findings" into "here are the 5 most important
things to fix first, with specific instructions for each."

The Business edition extends this with effort estimates and quick-fix vs.
comprehensive strategies.

### Safety and Predictability

Unlike tools that scan everything they can find or modify files to "fix"
issues, Haskell Orchestrator:
- Scans only what you explicitly tell it to scan
- Never modifies any files
- Never accesses the network during local scans
- Never collects telemetry
- Produces deterministic output

This makes it safe to run in any environment, including production CI
pipelines, security-sensitive environments, and regulated industries.

---

## When to Use Haskell Orchestrator

| Scenario | Fit |
|---|---|
| You maintain 1-5 repositories and want workflow hygiene checks | Good (Community) |
| Your team manages 5-50 repos and needs consolidated reporting | Good (Business) |
| Your org manages 50+ repos with compliance requirements | Good (Enterprise) |
| You need a YAML syntax linter | Use actionlint or yamllint instead |
| You need application code vulnerability scanning | Use CodeQL or similar instead |
| You need dependency version management | Use Dependabot or Renovate instead |
| You need to auto-fix workflow files | Not supported (by design) |

---

## Summary

Haskell Orchestrator exists because GitHub Actions workflows are
infrastructure code that deserves the same quality controls as application
code. Generic linters catch syntax errors. Security scanners catch
vulnerabilities. Haskell Orchestrator catches drift, policy violations,
structural defects, and standardisation failures across your entire workflow
estate, and produces actionable remediation plans to fix them.
