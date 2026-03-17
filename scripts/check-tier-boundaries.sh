#!/usr/bin/env bash
set -euo pipefail

# Verify Community edition does not contain premium features.
# This script fails if Community code imports Business or Enterprise modules.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
FAIL=0

echo "Tier Boundary Check: Community"
echo "================================"

# Community must NOT import OrchestratorBusiness or OrchestratorEnterprise
if grep -rI --include='*.hs' 'OrchestratorBusiness\|OrchestratorEnterprise' "$REPO_DIR/src/" "$REPO_DIR/app/" 2>/dev/null; then
  printf "${RED}FAIL${NC}: Community code imports premium modules\n"
  FAIL=1
else
  printf "${GREEN}PASS${NC}: No premium module imports\n"
fi

# Community must not have batch scanning module
if [ -f "$REPO_DIR/src/Orchestrator/Batch.hs" ]; then
  printf "${RED}FAIL${NC}: Community contains Batch module (Business feature)\n"
  FAIL=1
else
  printf "${GREEN}PASS${NC}: No batch module\n"
fi

# Community must not have governance module
if [ -f "$REPO_DIR/src/Orchestrator/Governance.hs" ]; then
  printf "${RED}FAIL${NC}: Community contains Governance module (Enterprise feature)\n"
  FAIL=1
else
  printf "${GREEN}PASS${NC}: No governance module\n"
fi

# Community must not have audit module
if [ -f "$REPO_DIR/src/Orchestrator/Audit.hs" ]; then
  printf "${RED}FAIL${NC}: Community contains Audit module (Enterprise feature)\n"
  FAIL=1
else
  printf "${GREEN}PASS${NC}: No audit module\n"
fi

# Community must not have HTML/CSV report module
if [ -f "$REPO_DIR/src/Orchestrator/Report.hs" ]; then
  printf "${RED}FAIL${NC}: Community contains Report module (Business feature)\n"
  FAIL=1
else
  printf "${GREEN}PASS${NC}: No premium report module\n"
fi

if [ $FAIL -eq 0 ]; then
  printf "\n${GREEN}All tier boundary checks passed.${NC}\n"
else
  printf "\n${RED}Tier boundary violations detected.${NC}\n"
  exit 1
fi
