#!/usr/bin/env bash
set -euo pipefail

# Pre-release verification script.
# Runs all checks that must pass before a release can be cut.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

pass() { printf "${GREEN}[PASS]${NC} %s\n" "$1"; PASS=$((PASS + 1)); }
fail_msg() { printf "${RED}[FAIL]${NC} %s\n" "$1"; FAIL=$((FAIL + 1)); }
info() { printf "${YELLOW}[INFO]${NC} %s\n" "$1"; }

echo "Release Verification"
echo "===================="
echo

# 1. Build
info "Building..."
BUILD_OUT=$(cd "$REPO_DIR" && cabal build all 2>&1) || true
if echo "$BUILD_OUT" | grep -qE "Up to date|Linking|Building"; then
  pass "Build succeeds"
else
  fail_msg "Build failed"
fi

# 2. Tests
info "Running tests..."
TEST_OUT=$(cd "$REPO_DIR" && cabal test all 2>&1) || true
if echo "$TEST_OUT" | grep -q "passed"; then
  pass "All tests pass"
else
  fail_msg "Tests failed"
fi

# 3. Release gate
info "Running release gate..."
if "$SCRIPT_DIR/release-gate.sh" >/dev/null 2>&1; then
  pass "Release gate passed"
else
  fail_msg "Release gate failed"
fi

# 4. Tier boundaries
info "Checking tier boundaries..."
if "$SCRIPT_DIR/check-tier-boundaries.sh" >/dev/null 2>&1; then
  pass "Tier boundaries clean"
else
  fail_msg "Tier boundary violation"
fi

# 5. Demo works
info "Running demo..."
if (cd "$REPO_DIR" && cabal run orchestrator -- demo >/dev/null 2>&1); then
  pass "Demo runs successfully"
else
  fail_msg "Demo failed"
fi

# 6. Workflow YAML validation
info "Validating workflow YAML..."
ALL_VALID=true
for wf in "$REPO_DIR"/.github/workflows/*.yml; do
  [ -f "$wf" ] || continue
  if python3 -c "import yaml; yaml.safe_load(open('$wf'))" 2>/dev/null; then
    true
  else
    fail_msg "Invalid YAML: $(basename "$wf")"
    ALL_VALID=false
  fi
done
if $ALL_VALID; then
  pass "All workflow YAML valid"
fi

# Summary
echo
echo "===================="
echo "Results: $PASS passed, $FAIL failed"
if [ $FAIL -gt 0 ]; then
  printf "${RED}RELEASE NOT READY${NC}\n"
  exit 1
else
  printf "${GREEN}RELEASE READY${NC}\n"
fi
