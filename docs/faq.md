# Frequently Asked Questions — Haskell Orchestrator

Author: Jamal Al-Sarraf

---

### 1. Does this tool modify my workflow files?

No. All operations (scan, validate, diff, plan, demo, doctor, rules,
explain, verify) are strictly read-only. The tool produces reports and
plans as text output. You review and apply changes manually. The only
command that writes to disk is `init`, which creates a new configuration
file and will not overwrite an existing one.

---

### 2. Do I need to know Haskell to use this?

No. The compiled binary is a standalone CLI tool. You install it, point it
at a repository, and read the output. Haskell knowledge is only needed if
you want to modify the tool itself or write custom policy rules at the
source level.

---

### 3. Can this scan private GitHub repositories?

Yes, if you provide a GitHub token with appropriate access. Set the
`GITHUB_TOKEN` environment variable before running the scan. Local path
scans do not require a token.

---

### 4. Is this tool safe to run in CI?

Yes. It is read-only, has no side effects, requires no elevated permissions,
and does not access the network during local scans. It is designed
specifically to be safe in CI pipelines.

---

### 5. What does the tool actually scan?

It scans `.github/workflows/*.yml` and `.github/workflows/*.yaml` files
under the paths you specify. It parses them into a typed domain model,
validates structural correctness, and evaluates them against a policy
engine. It does not scan application source code, Dockerfiles, Terraform
files, or other CI system configurations.

---

### 6. How is this different from actionlint?

actionlint is a GitHub Actions YAML linter that checks syntax and schema
conformance. Haskell Orchestrator is a policy-driven analysis tool that
checks for permissions hygiene, security practices, structural quality,
naming conventions, and workflow standardisation. They are complementary:
actionlint catches syntax errors, Haskell Orchestrator catches policy
violations and drift.

---

### 7. How is this different from Dependabot?

Dependabot manages dependency version updates in application code and
GitHub Actions. Haskell Orchestrator analyses the structure and policy
compliance of workflow files themselves. They solve different problems.
Dependabot will propose a PR to bump an action version; Haskell
Orchestrator will tell you that the action reference is not pinned to a
commit SHA.

---

### 8. Can I disable specific rules?

Yes. In your `.orchestrator.yml` configuration:

```yaml
policy:
  disabled: [NAME-001, NAME-002, TRIG-001]
```

You can also raise the minimum severity threshold to suppress lower-severity
findings:

```yaml
policy:
  min_severity: warning
```

---

### 9. What happens if the tool finds no workflows?

It reports "No workflows found" and exits successfully. Verify that the
target path contains a `.github/workflows/` directory with `.yml` or
`.yaml` files.

---

### 10. Does the tool support monorepos?

Yes. Point it at the root of a monorepo and it will scan the
`.github/workflows/` directory. If your monorepo has multiple workflow
directories (non-standard layout), specify each path explicitly.

---

### 11. Can I use this with GitHub Enterprise Server?

Local path scanning works with any repository regardless of where it is
hosted. For remote API scanning against GitHub Enterprise Server, you would
need to configure the API endpoint. The Community edition focuses on local
path scanning.

---

### 12. Is there a Docker image?

Not currently. The recommended approach is to build from source using GHC
and Cabal, or download a pre-built binary from the GitHub releases page.

---

### 13. How do I interpret severity levels?

| Severity | Meaning |
|---|---|
| Critical | Immediate security or operational risk requiring urgent attention |
| Error | Significant issue that should be fixed before merging |
| Warning | Best-practice violation that should be addressed |
| Info | Improvement suggestion or informational observation |

Use `policy.min_severity` to set the threshold for your environment.
For CI gates, `warning` or `error` is typical.

---

### 14. Can I fail my CI pipeline based on findings?

Yes. The tool's exit code can be used for gating. A common pattern:

```yaml
- name: Scan workflows
  run: |
    orchestrator scan . 2>&1
    # Fail if any Error or Critical findings exist
    orchestrator --json scan . | jq -e '[.findings[] | select(.severity == "Error" or .severity == "Critical")] | length == 0'
```

Or use the `policy.min_severity` setting to control what gets reported
and check the finding count in the output.

---

### 15. How often should I run scans?

Recommended patterns:
- **On every pull request** that modifies `.github/workflows/`
- **Weekly scheduled scan** of the full repository to detect drift
- **After major dependency updates** to verify nothing regressed
- **Before releases** as a pre-flight check

---

### 16. What is the performance impact?

Scanning is fast. A typical repository with 5-10 workflow files completes
in under a second. The tool reads YAML files, parses them into memory,
evaluates policy rules (which are pure functions), and renders output.
There is no network I/O, no database, and no indexing step.

---

### 17. Can I write custom policy rules?

In the Community edition, custom rules require modifying the Haskell source
code. Each rule is a function of type `Workflow -> [Finding]`, which is
straightforward to implement if you are familiar with Haskell. The standard
pack rules in `src/Orchestrator/Policy.hs` serve as templates.

---

### 18. What is the difference between scan, validate, and diff?

- **scan** runs the full policy engine and reports all findings with
  severity tags, file paths, and remediation suggestions.
- **validate** checks structural correctness (empty jobs, dangling needs,
  duplicate IDs) without evaluating policy rules.
- **diff** presents current issues in a concise format optimised for
  quick review and comparison.

---

### 19. Does the tool collect any data or phone home?

No. There is no telemetry, analytics, crash reporting, update checking,
or any form of network communication initiated by the tool. See the
[Safety Model](safety-model.md) for full details.

---

### 20. What platforms are supported?

Linux x86_64 is the primary supported platform. macOS and Windows may work
but are not tested. The tool is standard compiled Haskell with no
platform-specific system calls beyond basic file I/O.

---

### 21. How do I upgrade to Business or Enterprise?

See the [Edition Comparison](edition-comparison.md) for feature differences,
upgrade paths, and licensing details. Each edition is a separate binary;
upgrading does not require migrating data or reconfiguring the Community
installation.

---

### 22. Can the tool scan workflow files outside of `.github/workflows/`?

The tool expects workflows to be in the standard `.github/workflows/`
location within the specified scan target. If your workflows are stored
elsewhere, provide the direct path to the directory containing the YAML
files.
