# Safety Model — Haskell Orchestrator

Author: Jamal Al-Sarraf

---

## Overview

Haskell Orchestrator is designed around a strict safety model. The core
principle is that running the tool should never cause harm, side effects,
or surprises. Every design decision favours predictability and operator
control over convenience or automation.

---

## The Four Pillars

### 1. Read-Only by Default

All core operations — `scan`, `validate`, `diff`, `plan`, `demo`, `doctor`,
`rules`, `explain`, `verify` — are strictly read-only. They read workflow
YAML files from disk and produce text or JSON output. No files are created,
modified, or deleted during these operations.

The only command that writes to disk is `init`, which creates a new
`.orchestrator.yml` configuration file. It will not overwrite an existing
file.

This means:
- Running `orchestrator scan` in a production CI pipeline has zero
  side effects on the repository.
- Running `orchestrator plan` produces a remediation plan as text output.
  It does not apply the plan. The operator reviews and acts on the plan
  manually.
- There is no `--apply`, `--fix`, or `--auto-remediate` flag. The tool
  is an analysis and reporting instrument, not a mutation engine.

### 2. Explicit Targets Only

The tool never discovers repositories, directories, or files on its own.
Every scan target must be explicitly provided by the operator, either as
a command-line argument or in the configuration file.

This means:
- No home-directory crawling. The tool will not traverse `~/` looking for
  repositories.
- No automatic filesystem discovery. The tool does not scan `/`, `/tmp`,
  or any path the operator did not specify.
- No hidden file access. The tool does not read dotfiles, SSH keys,
  credentials, environment files, or anything outside the scan scope.
- No recursive upward traversal. The tool does not walk parent directories
  looking for configuration or workflow files.

If you run `orchestrator scan /path/to/repo`, the tool scans
`/path/to/repo/.github/workflows/` and nothing else. If that directory does
not exist or contains no workflow files, the tool reports "no workflows found"
and exits.

### 3. No Network Access During Local Scans

When scanning a local filesystem path, the tool performs no network I/O.
There are no HTTP requests, DNS lookups, or socket connections. The scan
is a pure filesystem read operation.

Network access occurs only when the operator explicitly requests a GitHub
API scan (e.g., scanning a remote repository by owner/name). Even then,
the tool uses only the specific API endpoints needed to fetch workflow
file contents and nothing more.

### 4. No Telemetry

The tool does not collect, transmit, or store any usage data, analytics,
crash reports, or metrics. There is:
- No phone-home behaviour
- No anonymous usage tracking
- No crash reporting service
- No feature flag service
- No update checking
- No background processes or daemons
- No persistent state between runs (except configuration files the operator
  explicitly creates)

---

## Operational Boundaries

### What the Tool Reads

| Resource | When | Purpose |
|---|---|---|
| `.github/workflows/*.yml` / `.yaml` | During scan/validate/diff/plan | Workflow analysis |
| `.orchestrator.yml` | At startup (if present) | Configuration |
| Environment variables | At startup (if GitHub API is used) | GitHub token for remote scans |
| Synthetic fixtures in `demo/` | During `demo` command | Built-in demonstration |

### What the Tool Does NOT Read

- Home directory contents
- SSH keys or known_hosts
- Git configuration (`.gitconfig`, `.git/`)
- Docker configuration
- Cloud provider credentials
- Browser history or cookies
- System logs
- Other repositories not explicitly targeted
- Package manager caches
- Temporary files from other tools

### What the Tool Writes

| Resource | When | Purpose |
|---|---|---|
| `.orchestrator.yml` | `init` command only | New configuration file (does not overwrite) |
| stdout | Always | Findings, plans, reports |
| stderr | On errors | Error messages |

### What the Tool Does NOT Write

- Workflow files (never modified)
- Git objects or refs
- Temporary files
- Log files
- Cache files
- Lock files
- PID files
- Sockets

---

## Resource Bounding

The tool is resource-bounded with conservative defaults:

| Resource | Default | Maximum | Control |
|---|---|---|---|
| Parallel workers | 1 (safe profile) | CPU count | `--jobs N` or `resources.jobs` |
| Directory traversal depth | 10 | Configurable | `scan.max_depth` |
| Symlink following | Disabled | Configurable | `scan.follow_symlinks` |

Memory usage is proportional to the number of workflow files being processed
concurrently. Each parsed workflow is a small in-memory data structure
(typically a few kilobytes). There is no background indexing, caching, or
accumulation of state across scans.

---

## Determinism

Given the same input files and the same configuration, the tool always
produces the same findings. There is no randomness, no time-dependent
logic, no external service dependency, and no non-deterministic ordering
in the output.

This means:
- Scan results are reproducible across machines and CI runs.
- Findings can be diffed across versions to detect regressions.
- Plans are stable and do not vary between runs.

---

## Process Model

The tool runs as a single process with no child processes, no daemons,
and no background threads (beyond what the Haskell runtime provides for
garbage collection). When the command completes, the process exits. There
is nothing to clean up, shut down, or terminate.

---

## Trust Model

The tool trusts:
- The operator to provide correct scan targets
- The filesystem to return correct file contents
- The YAML parser library to handle untrusted input safely
- The Haskell runtime to provide memory safety

The tool does not trust:
- Workflow file contents (they are untrusted input parsed defensively)
- Network responses (when using GitHub API, responses are validated)
- Configuration values (validated and bounded at load time)

---

## What Could Go Wrong

Despite the safety model, operators should be aware of:

1. **False positives.** The policy engine checks structural patterns, not
   runtime behaviour. A finding may not represent a real problem in your
   specific context. Use `policy.disabled` to suppress rules that do not
   apply.

2. **False negatives.** The tool does not detect all possible workflow
   issues. It checks for the patterns encoded in its policy rules and
   structural validators. Absence of findings does not mean a workflow
   is secure or correct.

3. **YAML parser limitations.** The parser handles standard GitHub Actions
   YAML. Exotic YAML features (anchors, merge keys, custom tags) may not
   be fully modeled.

4. **Stale configuration.** If your `.orchestrator.yml` disables rules or
   raises the minimum severity threshold, you may miss findings that would
   otherwise be reported.

---

## Comparison to Other Tools

Most CI/CD analysis tools operate with a "scan everything, report everything"
model. Haskell Orchestrator explicitly rejects this in favour of:

- Operator-controlled scope (you say what to scan)
- Zero side effects (nothing changes)
- Zero telemetry (nothing is reported back)
- Zero implicit behaviour (nothing happens that you did not ask for)

This makes the tool suitable for environments where security, auditability,
and predictability are more important than automatic discovery.
