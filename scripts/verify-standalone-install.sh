#!/usr/bin/env bash
set -euo pipefail

# Verify that the orchestrator binary works as a standalone installation.
# This script checks that the binary runs correctly without any other
# edition or source tree present.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

FAIL=0
PASS=0
WARN=0

pass() { printf "${GREEN}PASS${NC}: %s\n" "$1"; PASS=$((PASS + 1)); }
fail() { printf "${RED}FAIL${NC}: %s\n" "$1"; FAIL=$((FAIL + 1)); }
warn() { printf "${YELLOW}WARN${NC}: %s\n" "$1"; WARN=$((WARN + 1)); }

echo "=== Standalone Install Verification: orchestrator (Community) ==="
echo ""

# Determine binary location
BINARY="${1:-}"
if [ -z "$BINARY" ]; then
  # Try common locations
  for candidate in \
    "$REPO_DIR/_bin/orchestrator" \
    "$HOME/.cabal/bin/orchestrator" \
    "$HOME/.local/bin/orchestrator" \
    "$(command -v orchestrator 2>/dev/null || true)"; do
    if [ -n "$candidate" ] && [ -x "$candidate" ]; then
      BINARY="$candidate"
      break
    fi
  done
fi

if [ -z "$BINARY" ] || [ ! -x "$BINARY" ]; then
  echo "Usage: $0 [PATH_TO_BINARY]"
  echo ""
  echo "No orchestrator binary found. Build first with:"
  echo "  cabal build all && cabal install exe:orchestrator --installdir=_bin"
  exit 1
fi

# Resolve to absolute path
BINARY="$(cd "$(dirname "$BINARY")" && pwd)/$(basename "$BINARY")"

echo "Binary: $BINARY"
echo "Size:   $(du -h "$BINARY" | cut -f1)"
echo ""

# 1. Binary executes without error
echo "[1/8] Binary executes..."
if "$BINARY" --help >/dev/null 2>&1; then
  pass "Binary runs and responds to --help"
else
  fail "Binary failed to execute"
fi

# 2. Demo mode works (no external access)
echo "[2/8] Demo mode..."
if DEMO_OUT=$("$BINARY" demo 2>&1); then
  pass "Demo mode completes successfully"
else
  fail "Demo mode failed: $DEMO_OUT"
fi

# 3. Rules listing works
echo "[3/8] Rules listing..."
if RULES_OUT=$("$BINARY" rules 2>&1); then
  RULE_COUNT=$(echo "$RULES_OUT" | grep -c 'PERM\|SEC\|RUN\|CONC\|RES\|NAME\|TRIG' || true)
  if [ "$RULE_COUNT" -ge 10 ]; then
    pass "Rules command lists $RULE_COUNT rules (expected >= 10)"
  else
    warn "Rules command returned only $RULE_COUNT rules (expected >= 10)"
  fi
else
  fail "Rules command failed"
fi

# 4. Doctor command works
echo "[4/8] Doctor command..."
if "$BINARY" doctor >/dev/null 2>&1; then
  pass "Doctor command completes"
else
  # Doctor may warn about missing config — that's okay
  warn "Doctor command exited with warnings (acceptable for fresh install)"
fi

# 5. Init command works
echo "[5/8] Init command (temp directory)..."
TMPDIR_INIT=$(mktemp -d)
ORIG_DIR=$(pwd)
if cd "$TMPDIR_INIT" && "$BINARY" init >/dev/null 2>&1; then
  if [ -f "$TMPDIR_INIT/.orchestrator.yml" ]; then
    pass "Init creates .orchestrator.yml"
  else
    fail "Init ran but .orchestrator.yml not created"
  fi
else
  fail "Init command failed"
fi
cd "$ORIG_DIR"
rm -rf "$TMPDIR_INIT"

# 6. Explain command works
echo "[6/8] Rule explanation..."
if "$BINARY" explain SEC-001 >/dev/null 2>&1; then
  pass "Explain command works for SEC-001"
else
  fail "Explain command failed"
fi

# 7. JSON output mode
echo "[7/8] JSON output mode..."
if JSON_OUT=$("$BINARY" --json demo 2>&1); then
  pass "JSON output mode works"
else
  warn "JSON output mode returned non-zero (may be expected if findings exist)"
fi

# 8. Binary is self-contained (no runtime deps on other editions)
echo "[8/8] Edition independence..."
if command -v ldd >/dev/null 2>&1; then
  if ldd "$BINARY" 2>/dev/null | grep -qi 'orchestrator-business\|orchestrator-enterprise'; then
    fail "Binary links against other edition libraries"
  else
    pass "Binary has no runtime dependency on other editions"
  fi
elif command -v otool >/dev/null 2>&1; then
  if otool -L "$BINARY" 2>/dev/null | grep -qi 'orchestrator-business\|orchestrator-enterprise'; then
    fail "Binary links against other edition libraries"
  else
    pass "Binary has no runtime dependency on other editions"
  fi
else
  warn "Cannot check dynamic linking (no ldd or otool available)"
fi

echo ""
echo "=== Results ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "Warnings: $WARN"
echo ""

if [ "$FAIL" -gt 0 ]; then
  printf "${RED}Standalone verification FAILED${NC}\n"
  exit 1
else
  printf "${GREEN}Standalone verification PASSED${NC}\n"
fi
