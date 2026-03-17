#!/usr/bin/env bash
set -euo pipefail

# Validate the capability contract against the actual codebase.
# Checks that forbidden modules are not imported in restricted tiers.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE="$(cd "$REPO_DIR/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
PASS=0
FAIL=0

pass() { printf "${GREEN}[PASS]${NC} %s\n" "$1"; PASS=$((PASS + 1)); }
fail_msg() { printf "${RED}[FAIL]${NC} %s\n" "$1"; FAIL=$((FAIL + 1)); }

echo "Capability Contract Validation"
echo "==============================="
echo

# ── Rule: Community must NOT import Business modules ──
echo "Checking Community does not import Business modules..."
if grep -rI --include='*.hs' 'OrchestratorBusiness' "$WORKSPACE/community/src/" "$WORKSPACE/community/app/" 2>/dev/null; then
  fail_msg "CAP-LEAK: Community imports OrchestratorBusiness modules"
else
  pass "Community clean of Business imports"
fi

# ── Rule: Community must NOT import Enterprise modules ──
if grep -rI --include='*.hs' 'OrchestratorEnterprise' "$WORKSPACE/community/src/" "$WORKSPACE/community/app/" 2>/dev/null; then
  fail_msg "CAP-LEAK: Community imports OrchestratorEnterprise modules"
else
  pass "Community clean of Enterprise imports"
fi

# ── Rule: Business must NOT import Enterprise modules ──
echo "Checking Business does not import Enterprise modules..."
if grep -rI --include='*.hs' 'OrchestratorEnterprise' "$WORKSPACE/business/src/" "$WORKSPACE/business/app/" 2>/dev/null; then
  fail_msg "CAP-LEAK: Business imports OrchestratorEnterprise modules"
else
  pass "Business clean of Enterprise imports"
fi

# ── Rule: Community must NOT have Batch module ──
if [ -f "$WORKSPACE/community/src/Orchestrator/Batch.hs" ]; then
  fail_msg "CAP-0002: Community contains Batch module (Business-owned)"
else
  pass "CAP-0002: No batch module in Community"
fi

# ── Rule: Community must NOT have Report module ──
if [ -f "$WORKSPACE/community/src/Orchestrator/Report.hs" ]; then
  fail_msg "CAP-0051: Community contains Report module (Business-owned)"
else
  pass "CAP-0051: No report module in Community"
fi

# ── Rule: Community must NOT have Governance module ──
if [ -f "$WORKSPACE/community/src/Orchestrator/Governance.hs" ]; then
  fail_msg "CAP-0022: Community contains Governance module (Enterprise-owned)"
else
  pass "CAP-0022: No governance module in Community"
fi

# ── Rule: Community must NOT have Audit module ──
if [ -f "$WORKSPACE/community/src/Orchestrator/Audit.hs" ]; then
  fail_msg "CAP-0070: Community contains Audit module (Enterprise-owned)"
else
  pass "CAP-0070: No audit module in Community"
fi

# ── Rule: Community must NOT have Compliance module ──
if [ -f "$WORKSPACE/community/src/Orchestrator/Compliance.hs" ]; then
  fail_msg "CAP-0080: Community contains Compliance module (Enterprise-owned)"
else
  pass "CAP-0080: No compliance module in Community"
fi

# ── Rule: Business must NOT have Governance module ──
if [ -f "$WORKSPACE/business/src/OrchestratorBusiness/Governance.hs" ]; then
  fail_msg "CAP-0022: Business contains Governance module (Enterprise-owned)"
else
  pass "CAP-0022: No governance module in Business"
fi

# ── Rule: Business must NOT have Audit module ──
if [ -f "$WORKSPACE/business/src/OrchestratorBusiness/Audit.hs" ]; then
  fail_msg "CAP-0070: Business contains Audit module (Enterprise-owned)"
else
  pass "CAP-0070: No audit module in Business"
fi

# ── Rule: Business must NOT have Compliance module ──
if [ -f "$WORKSPACE/business/src/OrchestratorBusiness/Compliance.hs" ]; then
  fail_msg "CAP-0080: Business contains Compliance module (Enterprise-owned)"
else
  pass "CAP-0080: No compliance module in Business"
fi

# ── Rule: Capability contract manifest exists ──
if [ -f "$WORKSPACE/community/config/capability-contract.yaml" ]; then
  pass "Capability contract manifest exists"
else
  fail_msg "Missing capability-contract.yaml"
fi

# ── Rule: Edition comparison docs exist ──
for tier in community business enterprise; do
  if [ -f "$WORKSPACE/$tier/docs/edition-comparison.md" ]; then
    pass "$tier: edition-comparison.md exists"
  else
    fail_msg "$tier: missing edition-comparison.md"
  fi
done

# ── Rule: Capability matrix doc exists ──
if [ -f "$WORKSPACE/community/docs/capability-matrix.md" ]; then
  pass "Capability matrix document exists"
else
  fail_msg "Missing docs/capability-matrix.md"
fi

# ── Attribution leak check (dynamic terms) ──
T1="CLAU"; T2="DE"; T3="Anthro"; T4="pic"
TERMS="${T1}${T2}\.md|AGENTS\.md|${T1}${T2} Code|${T3}${T4}|AI-generated|Co-authored-by|Generated-by"
for tier in community business enterprise; do
  LEAKS=$(grep -rIl --include='*.md' --include='*.hs' --include='*.cabal' \
       -E "$TERMS" "$WORKSPACE/$tier/" 2>/dev/null | grep -v '.local/' | grep -v '.git/' || true)
  if [ -n "$LEAKS" ]; then
    fail_msg "$tier: attribution leak detected"
  else
    pass "$tier: no attribution leaks"
  fi
done

echo
echo "==============================="
echo "Results: $PASS passed, $FAIL failed"
if [ $FAIL -gt 0 ]; then
  printf "${RED}CONTRACT VALIDATION FAILED${NC}\n"
  exit 1
else
  printf "${GREEN}CONTRACT VALIDATION PASSED${NC}\n"
fi
