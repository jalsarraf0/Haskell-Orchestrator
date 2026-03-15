# Remediation Philosophy

## Read-Only First

Orchestrator is read-only by default. It never modifies workflow files,
creates PRs, or changes repository settings. It observes, analyzes, and
reports.

This is deliberate:
- Changes to CI/CD workflows can break deployments
- Automated changes without review are risky
- The operator should always understand and approve changes
- Read-only analysis is safe to run anywhere, anytime

## Plan Before Act

The remediation workflow is:

1. **Scan** — discover current state
2. **Validate** — check structural correctness
3. **Diff** — see what deviates from policy
4. **Plan** — generate ordered remediation steps
5. **Review** — the operator reviews the plan
6. **Apply** — the operator makes changes manually

Steps 1-4 are automated. Steps 5-6 are human decisions.

## Dry-Run Default

All operations default to observation mode. There is no `--force` flag that
writes changes. This ensures:

- No accidental modifications
- Safe to integrate into CI without side effects
- Safe to run against production repositories
- No risk of breaking workflows during analysis

## Deterministic Output

Given the same input and configuration, Orchestrator always produces the
same findings and plans. This means:

- CI results are reproducible
- Plans can be reviewed and re-generated
- No hidden randomness or state
- Output is suitable for automated comparison

## Severity-Driven Prioritization

Findings are ranked by severity (Critical > Error > Warning > Info).
Remediation plans prioritize higher-severity issues first. This helps
operators focus on what matters most.

The default minimum severity is Info (report everything). Operators can
raise the threshold to Warning or Error to focus on actionable items.
