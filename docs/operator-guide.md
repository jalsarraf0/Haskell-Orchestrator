# Operator Guide — Community Edition

## Integration into CI/CD

Add Orchestrator as a CI step to validate workflows on every PR:

```yaml
- name: Validate workflows
  run: |
    orchestrator scan . --json > findings.json
    orchestrator plan .
```

The exit code is non-zero if Error or Critical findings exist, making it
suitable as a CI gate.

## Configuration Tuning

### Adjusting Severity Threshold

To reduce noise, raise the minimum severity:

```yaml
policy:
  min_severity: warning  # Skip Info-level findings
```

### Disabling Specific Rules

If a rule doesn't apply to your project:

```yaml
policy:
  disabled: [NAME-001, NAME-002, RUN-001]
```

### Resource Control

For large repositories:

```yaml
resources:
  profile: balanced  # Or: safe (default), fast
```

## Recommended Workflow

1. **Start with demo**: `orchestrator demo` to see what the tool does
2. **Init config**: `orchestrator init` to create a config file
3. **First scan**: `orchestrator scan .` to see current state
4. **Review plan**: `orchestrator plan .` for remediation steps
5. **Fix incrementally**: Address Error findings first, then Warnings
6. **Add to CI**: Gate PRs on scan results

## Scaling Beyond Community

If you manage more than a few repositories and need:
- Batch scanning across many repos
- HTML/CSV reports for stakeholders
- Team-specific policy rules

Consider the Business edition.

If you need org-wide governance, audit trails, or compliance:
Consider the Enterprise edition.
