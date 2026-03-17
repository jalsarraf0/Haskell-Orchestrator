# Output Examples — Haskell Orchestrator Community Edition

Author: Jamal Al-Sarraf

---

This document shows representative CLI output for each command. Actual
output depends on the workflows being scanned and the active configuration.

---

## `orchestrator scan /path/to/repo`

```
Scan Results
────────────────────────────────────────────────────────────
Files scanned: 3
Findings:      7
────────────────────────────────────────────────────────────

[WARNING]  [PERM-001] Workflow does not declare a top-level permissions block.
  Without explicit permissions, the workflow runs with default token
  permissions which may be overly broad.
  File: .github/workflows/ci.yml
  Fix: Add a 'permissions:' block to restrict token scope.

[ERROR]    [PERM-002] Workflow uses 'write-all' permissions, granting broad access.
  File: .github/workflows/release.yml
  Fix: Use fine-grained permissions instead of 'write-all'.

[WARNING]  [SEC-001] Step uses unpinned action: slackapi/slack-github-action@v1.24.0.
  Supply-chain risk: tag references can be mutated.
  File: .github/workflows/ci.yml
  Fix: Pin to a full commit SHA instead of a tag.

[ERROR]    [SEC-002] Run step references secrets directly. Secrets in shell
  commands risk exposure in build logs.
  File: .github/workflows/deploy.yml
  Fix: Pass secrets via environment variables instead.

[WARNING]  [RES-001] Job 'build' has no timeout-minutes. Runaway jobs can
  consume resources indefinitely.
  File: .github/workflows/ci.yml
  Fix: Add 'timeout-minutes:' to bound execution time.

[INFO]     [CONC-001] Workflow has pull_request trigger but no concurrency config.
  Duplicate runs may waste resources.
  File: .github/workflows/ci.yml
  Fix: Add 'concurrency:' with cancel-in-progress for PR workflows.

[INFO]     [NAME-002] Job ID 'BuildAndTest' does not follow kebab-case.
  File: .github/workflows/ci.yml
  Fix: Use kebab-case for job IDs (e.g., 'build-and-test').
```

---

## `orchestrator --json scan /path/to/repo`

```json
{
  "target": {
    "type": "local",
    "path": "/path/to/repo"
  },
  "files": [
    ".github/workflows/ci.yml",
    ".github/workflows/release.yml",
    ".github/workflows/deploy.yml"
  ],
  "findings": [
    {
      "severity": "Warning",
      "category": "Permissions",
      "rule_id": "PERM-001",
      "message": "Workflow does not declare a top-level permissions block. Without explicit permissions, the workflow runs with default token permissions which may be overly broad.",
      "file": ".github/workflows/ci.yml",
      "remediation": "Add a 'permissions:' block to restrict token scope."
    },
    {
      "severity": "Error",
      "category": "Permissions",
      "rule_id": "PERM-002",
      "message": "Workflow uses 'write-all' permissions, granting broad access.",
      "file": ".github/workflows/release.yml",
      "remediation": "Use fine-grained permissions instead of 'write-all'."
    }
  ]
}
```

---

## `orchestrator validate /path/to/repo`

```
Validation Results
────────────────────────────────────────────────────────────
Files validated: 3

.github/workflows/ci.yml .............. OK
.github/workflows/release.yml ........ OK
.github/workflows/deploy.yml ......... 1 issue

Issues:
  [ERROR] .github/workflows/deploy.yml: Job 'notify' references
  non-existent job 'deply' in 'needs'. Did you mean 'deploy'?

Validated 3 files: 2 passed, 1 with issues.
```

---

## `orchestrator plan /path/to/repo`

```
Remediation Plan
════════════════════════════════════════════════════════════

Priority 1: Fix security errors (2 items)
────────────────────────────────────────────────────────────

  1. [PERM-002] .github/workflows/release.yml
     Issue: Workflow uses 'write-all' permissions.
     Action: Replace the top-level 'permissions: write-all' with
     fine-grained permissions. For a release workflow, typical scopes
     are:
       permissions:
         contents: write
         packages: write
     Review each job's actual needs and scope accordingly.

  2. [SEC-002] .github/workflows/deploy.yml
     Issue: Run step references secrets directly.
     Action: Move the secret reference from the 'run:' block to an
     'env:' mapping on the step:
       env:
         MY_SECRET: ${{ secrets.MY_SECRET }}
       run: echo "Using secret via env var"

Priority 2: Fix warnings (3 items)
────────────────────────────────────────────────────────────

  3. [PERM-001] .github/workflows/ci.yml
     Issue: No top-level permissions block.
     Action: Add a 'permissions:' block. Start with read-only defaults:
       permissions:
         contents: read

  4. [SEC-001] .github/workflows/ci.yml
     Issue: Unpinned third-party action.
     Action: Replace 'slackapi/slack-github-action@v1.24.0' with its
     full commit SHA. Find the SHA by visiting the action's releases
     page and identifying the commit for the desired version.

  5. [RES-001] .github/workflows/ci.yml
     Issue: Job 'build' has no timeout.
     Action: Add 'timeout-minutes: 30' (or appropriate value) to the
     job definition.

Priority 3: Improve hygiene (2 items)
────────────────────────────────────────────────────────────

  6. [CONC-001] .github/workflows/ci.yml
     Issue: PR workflow without concurrency cancellation.
     Action: Add concurrency configuration:
       concurrency:
         group: ${{ github.workflow }}-${{ github.ref }}
         cancel-in-progress: true

  7. [NAME-002] .github/workflows/ci.yml
     Issue: Job ID 'BuildAndTest' is not kebab-case.
     Action: Rename to 'build-and-test'.

════════════════════════════════════════════════════════════
Plan: 7 items across 3 priority levels.
Estimated scope: 5 files, 7 changes.
```

---

## `orchestrator diff /path/to/repo`

```
Current Issues
────────────────────────────────────────────────────────────

  ci.yml:
    [WARNING]  PERM-001  Missing permissions block
    [WARNING]  SEC-001   Unpinned action: slackapi/slack-github-action@v1.24.0
    [WARNING]  RES-001   Job 'build' missing timeout
    [INFO]     CONC-001  PR workflow without concurrency control
    [INFO]     NAME-002  Job 'BuildAndTest' not kebab-case

  release.yml:
    [ERROR]    PERM-002  write-all permissions

  deploy.yml:
    [ERROR]    SEC-002   Secret in run step

────────────────────────────────────────────────────────────
Total: 7 issues (2 errors, 3 warnings, 2 info)
```

---

## `orchestrator demo`

```
Haskell Orchestrator — Demo Mode
════════════════════════════════════════════════════════════

Running scan/validate/plan cycle against synthetic fixtures.
No external repositories are accessed.

Step 1: Scanning demo workflows...
  Parsed 2 synthetic workflow files.

Step 2: Evaluating policies...
  Found 5 findings across 2 workflows.

Step 3: Generating remediation plan...
  Plan contains 5 remediation steps.

────────────────────────────────────────────────────────────
Demo Findings:

[WARNING]  [PERM-001] Workflow does not declare a top-level permissions block.
  File: demo/workflows/build.yml
  Fix: Add a 'permissions:' block to restrict token scope.

[ERROR]    [PERM-002] Job 'deploy' uses 'write-all' permissions, granting
  broad access.
  File: demo/workflows/deploy.yml
  Fix: Use fine-grained permissions instead of 'write-all'.

[WARNING]  [SEC-001] Step uses unpinned action: some-org/some-action@v2.
  File: demo/workflows/build.yml
  Fix: Pin to a full commit SHA instead of a tag.

[WARNING]  [RES-001] Job 'test' has no timeout-minutes.
  File: demo/workflows/build.yml
  Fix: Add 'timeout-minutes:' to bound execution time.

[INFO]     [NAME-002] Job ID 'runTests' does not follow kebab-case.
  File: demo/workflows/build.yml
  Fix: Use kebab-case for job IDs (e.g., 'run-tests').

────────────────────────────────────────────────────────────
Summary: 1 error, 3 warnings, 1 info.

Demo complete. Run 'orchestrator scan /path/to/repo' to scan your own
workflows.
```

---

## `orchestrator doctor`

```
Orchestrator Doctor
────────────────────────────────────────────────────────────

  Configuration file:  .orchestrator.yml ... found
  Configuration valid: .................... yes
  Policy pack:         standard (10 rules)
  Disabled rules:      none
  Min severity:        info
  Resource profile:    safe (1 worker)
  GHC version:         9.6.7 .............. OK
  Cabal version:       3.14.2.0 ........... OK

All checks passed.
```

---

## `orchestrator rules`

```
Available Policy Rules (standard pack)
────────────────────────────────────────────────────────────

  ID        Severity  Category      Name
  ────────  ────────  ──────────    ────────────────────────
  PERM-001  Warning   Permissions   Permissions Required
  PERM-002  Error     Permissions   Broad Permissions
  RUN-001   Info      Runners       Self-Hosted Runner Detection
  CONC-001  Info      Concurrency   Missing Concurrency
  SEC-001   Warning   Security      Unpinned Actions
  SEC-002   Error     Security      Secret in Run Step
  RES-001   Warning   Structure     Missing Timeout
  NAME-001  Info      Naming        Workflow Naming
  NAME-002  Info      Naming        Job Naming Convention
  TRIG-001  Info      Triggers      Wildcard Triggers

10 rules in 1 pack.
Use 'orchestrator explain RULE_ID' for details.
```

---

## `orchestrator explain SEC-001`

```
Rule: SEC-001 — Unpinned Actions
────────────────────────────────────────────────────────────

  Severity:  Warning
  Category:  Security
  Pack:      standard

  Description:
    Third-party actions should be pinned to a full commit SHA rather
    than a mutable tag reference. Tag references (e.g., @v2, @main)
    can be moved to point to different commits without notice. If a
    third-party action's tag is compromised or retargeted, all
    workflows referencing that tag will execute the new code.

    Pinning to a commit SHA (40-character hex string) ensures that
    the exact code you reviewed is the code that runs.

  Example (before):
    uses: some-org/some-action@v2

  Example (after):
    uses: some-org/some-action@a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2

  How to find the SHA:
    Visit the action's GitHub releases page, identify the release
    corresponding to the tag you want, and note the full commit SHA.

  Related:
    - GitHub docs: "Security hardening for GitHub Actions"
    - PERM-002 (broad permissions amplify the impact of unpinned actions)

  Configuration:
    Disable this rule with:
      policy:
        disabled: [SEC-001]
```
