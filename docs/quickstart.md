# Quickstart Guide — Haskell Orchestrator Community Edition

Author: Jamal Al-Sarraf

---

## Choose Your Installation Method

**Option A: Download a pre-built binary** (recommended for most users).
Download from the [Releases](https://github.com/jalsarraf0/Haskell-Orchestrator/releases)
page. No Haskell toolchain needed. Skip to Step 2 after downloading.

**Option B: Build from source** (for developers or contributors).
Follow the steps below starting from Step 1.

No other edition (Business or Enterprise) is required. Community is
independently installable and self-contained.

---

## Prerequisites (Source Build Only)

- **GHC 9.6.x** (9.6.7 recommended)
- **Cabal 3.10+** (3.14 recommended)
- A repository containing `.github/workflows/*.yml` files to scan

If you are on a system with ghcup:

```bash
ghcup install ghc 9.6.7
ghcup set ghc 9.6.7
ghcup install cabal 3.14.2.0
```

Verify your toolchain:

```bash
ghc --version    # Expected: 9.6.7
cabal --version  # Expected: 3.10+
```

---

## Step 1: Clone and Build

```bash
git clone https://github.com/jalsarraf0/Haskell-Orchestrator.git
cd Haskell-Orchestrator
cabal update
cabal build all
```

Build time depends on whether cached dependencies exist. A clean build
typically takes 2-5 minutes.

---

## Step 2: Run the Demo

The demo runs a complete scan/validate/plan cycle against synthetic workflow
fixtures bundled with the project. No external repositories or network access
are involved.

```bash
cabal run orchestrator -- demo
```

Expected output includes:
- Parsed workflow summary
- Policy findings with severity tags
- A remediation plan

This confirms the tool is built correctly and operational.

---

## Step 3: Install the Binary

Install the `orchestrator` binary to your Cabal bin directory (typically
`~/.cabal/bin` or `~/.local/bin`):

```bash
cabal install exe:orchestrator
```

Verify it is on your PATH:

```bash
orchestrator --help
```

---

## Step 4: Check Your Environment

Run the doctor command to verify the environment and default configuration:

```bash
orchestrator doctor
```

Doctor checks:
- Whether a configuration file exists
- Whether the configuration is valid
- Whether scan targets are reachable
- General environment diagnostics

---

## Step 5: Scan a Repository

Point the scanner at a local repository that contains GitHub Actions workflows:

```bash
orchestrator scan /path/to/your/repo
```

The tool looks for `.github/workflows/*.yml` and `.github/workflows/*.yaml`
files under the specified path.

If no workflows are found, verify the path contains a `.github/workflows/`
directory.

---

## Step 6: Validate Workflow Structure

Structural validation checks for issues independent of policy rules:
empty jobs, dangling `needs` references, duplicate job IDs.

```bash
orchestrator validate /path/to/your/repo
```

---

## Step 7: View Current Issues (Diff)

The diff command presents current issues in a concise format suitable for
quick review:

```bash
orchestrator diff /path/to/your/repo
```

---

## Step 8: Generate a Remediation Plan

The plan command generates a step-by-step remediation plan for all findings:

```bash
orchestrator plan /path/to/your/repo
```

The plan is read-only output. It does not modify any files. You review the
plan and apply changes manually.

---

## Step 9: Initialize a Configuration File (Optional)

Create a `.orchestrator.yml` configuration file with documented defaults:

```bash
cd /path/to/your/repo
orchestrator init
```

This creates `.orchestrator.yml` in the current directory. Edit it to:
- Define explicit scan targets
- Set path exclusions
- Choose a minimum severity threshold
- Disable specific rules
- Adjust parallelism

Example configuration:

```yaml
scan:
  targets: ["."]
  exclude: [".github/workflows/deprecated/"]
  max_depth: 10
  follow_symlinks: false

policy:
  pack: standard
  min_severity: warning
  disabled: [NAME-001, NAME-002]

output:
  format: text
  verbose: false
  color: true

resources:
  jobs: 4
  profile: balanced
```

---

## Step 10: Explore Policy Rules

List all available policy rules:

```bash
orchestrator rules
```

Get a detailed explanation of any rule:

```bash
orchestrator explain SEC-001
orchestrator explain PERM-002
```

---

## Step 11: Use JSON Output

For pipeline integration or machine-readable output:

```bash
orchestrator --json scan /path/to/your/repo
```

The JSON output includes structured findings with severity, category, rule ID,
message, file path, and remediation suggestion.

---

## Common Flags

| Flag | Effect |
|---|---|
| `-c FILE` / `--config FILE` | Use a specific configuration file |
| `-v` / `--verbose` | Enable verbose output |
| `--json` | Output results as JSON |
| `-j N` / `--jobs N` | Set number of parallel workers |

---

## Next Steps

- Read the [Safety Model](safety-model.md) to understand isolation guarantees
- Read the [Operator Guide](operator-guide.md) for CI integration
- Read the [FAQ](faq.md) for common questions
- Review the [Remediation Philosophy](remediation-philosophy.md)
- Compare editions in the [Edition Comparison](edition-comparison.md)
