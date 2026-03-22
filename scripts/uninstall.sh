#!/usr/bin/env bash
set -euo pipefail

# Haskell Orchestrator — Official Uninstaller
# Removes installed binary, cleans Cabal store entries, and purges build artifacts.

PRODUCT="orchestrator"
CABAL_STORE="${CABAL_DIR:-$HOME/.cabal}/store"

# --- Colours (if terminal) ---
if [ -t 1 ]; then
  GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; BOLD='\033[1m'; RESET='\033[0m'
else
  GREEN=''; YELLOW=''; RED=''; BOLD=''; RESET=''
fi

info()  { printf "${GREEN}[uninstall]${RESET} %s\n" "$*"; }
warn()  { printf "${YELLOW}[uninstall]${RESET} %s\n" "$*"; }
error() { printf "${RED}[uninstall]${RESET} %s\n" "$*" >&2; }

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --purge            Also remove build cache (dist-newstyle) and config files
  --keep-store       Don't clean Cabal store (only remove binary)
  --system           Uninstall from /usr/local/bin (requires sudo)
  --dry-run          Show what would be removed without actually removing
  -y, --yes          Skip confirmation prompt
  -h, --help         Show this help
EOF
}

# --- Parse arguments ---
PURGE=false
CLEAN_STORE=true
USE_SUDO=""
DRY_RUN=false
AUTO_YES=false
SEARCH_DIRS=("$HOME/.local/bin" "$HOME/.cabal/bin" "/opt/haskell/cabal/bin")

while [ $# -gt 0 ]; do
  case "$1" in
    --purge)       PURGE=true; shift ;;
    --keep-store)  CLEAN_STORE=false; shift ;;
    --system)      SEARCH_DIRS+=("/usr/local/bin"); USE_SUDO="sudo"; shift ;;
    --dry-run)     DRY_RUN=true; shift ;;
    -y|--yes)      AUTO_YES=true; shift ;;
    -h|--help)     usage; exit 0 ;;
    *)             error "Unknown option: $1"; usage; exit 1 ;;
  esac
done

# --- Find installed binaries ---
find_binaries() {
  local found=()
  for dir in "${SEARCH_DIRS[@]}"; do
    for name in orchestrator orchestrator-enterprise orchestrator-business ci-orchestrator; do
      if [ -f "$dir/$name" ]; then
        found+=("$dir/$name")
      fi
    done
  done
  # Also check PATH
  local path_bin
  path_bin=$(command -v orchestrator 2>/dev/null || true)
  if [ -n "$path_bin" ]; then
    local already=false
    for f in "${found[@]:-}"; do
      [ "$f" = "$path_bin" ] && already=true
    done
    [ "$already" = false ] && found+=("$path_bin")
  fi
  printf '%s\n' "${found[@]:-}"
}

# --- Garbage collect Cabal store ---
gc_store() {
  info "Cleaning Cabal store entries..."

  local gc_count=0
  local gc_bytes=0
  local ghc_ver
  ghc_ver=$(ghc --numeric-version 2>/dev/null || echo "")

  if [ -z "$ghc_ver" ]; then
    warn "GHC not found — skipping store cleanup"
    return
  fi

  local store_dir="${CABAL_STORE}/ghc-${ghc_ver}"
  [ -d "$store_dir" ] || return

  local pkg_patterns=(
    "orchestrator-[0-9]*"
    "orchestrator-business-[0-9]*"
    "orchestrator-enterprise-[0-9]*"
    "haskell-ci-orchestrator-[0-9]*"
  )

  for pattern in "${pkg_patterns[@]}"; do
    while IFS= read -r -d '' entry; do
      local size
      size=$(du -sb "$entry" 2>/dev/null | cut -f1 || echo 0)
      gc_bytes=$((gc_bytes + size))
      gc_count=$((gc_count + 1))
      if [ "$DRY_RUN" = true ]; then
        info "[dry-run] Would remove: $entry ($(( size / 1024 )) KB)"
      else
        rm -rf "$entry"
      fi
    done < <(find "$store_dir" -maxdepth 1 -type d -name "$pattern" -print0 2>/dev/null)
  done

  # Clean package.db entries
  local pkg_db="$store_dir/package.db"
  if [ -d "$pkg_db" ]; then
    for pattern in "${pkg_patterns[@]}"; do
      while IFS= read -r -d '' conf; do
        gc_count=$((gc_count + 1))
        if [ "$DRY_RUN" = true ]; then
          info "[dry-run] Would remove: $conf"
        else
          rm -f "$conf"
        fi
      done < <(find "$pkg_db" -maxdepth 1 -name "${pattern}*.conf" -print0 2>/dev/null)
    done

    if [ "$DRY_RUN" = false ] && command -v ghc-pkg &>/dev/null; then
      ghc-pkg --package-db="$pkg_db" recache 2>/dev/null || true
    fi
  fi

  local gc_mb=$(( gc_bytes / 1048576 ))
  if [ "$gc_count" -gt 0 ]; then
    info "Collected $gc_count store entries (~${gc_mb} MB)"
  else
    info "No orchestrator store entries found"
  fi
}

# --- Purge build artifacts ---
purge_build() {
  info "Purging build artifacts..."

  # dist-newstyle in current directory (if run from repo root)
  if [ -d "dist-newstyle" ]; then
    local size
    size=$(du -sh dist-newstyle 2>/dev/null | cut -f1)
    if [ "$DRY_RUN" = true ]; then
      info "[dry-run] Would remove: dist-newstyle ($size)"
    else
      rm -rf dist-newstyle
      info "Removed dist-newstyle ($size)"
    fi
  fi

  # Config files
  if [ -f ".orchestrator.yml" ]; then
    if [ "$DRY_RUN" = true ]; then
      info "[dry-run] Would remove: .orchestrator.yml"
    else
      rm -f .orchestrator.yml
      info "Removed .orchestrator.yml"
    fi
  fi
}

# --- Main ---
main() {
  printf "${BOLD}Haskell Orchestrator Uninstaller${RESET}\n\n"

  # Find what's installed
  local binaries
  binaries=$(find_binaries)

  if [ -z "$binaries" ] && [ "$CLEAN_STORE" = false ]; then
    info "No orchestrator binaries found — nothing to uninstall"
    exit 0
  fi

  # Show plan
  printf "The following will be removed:\n\n"

  if [ -n "$binaries" ]; then
    printf "  ${BOLD}Binaries:${RESET}\n"
    while IFS= read -r bin; do
      printf "    %s\n" "$bin"
    done <<< "$binaries"
  fi

  if [ "$CLEAN_STORE" = true ]; then
    printf "  ${BOLD}Cabal store entries:${RESET} all orchestrator-related packages\n"
  fi

  if [ "$PURGE" = true ]; then
    printf "  ${BOLD}Build artifacts:${RESET} dist-newstyle, .orchestrator.yml\n"
  fi
  printf "\n"

  # Confirm
  if [ "$AUTO_YES" = false ] && [ "$DRY_RUN" = false ]; then
    printf "Proceed? [y/N] "
    read -r confirm
    case "$confirm" in
      y|Y|yes|YES) ;;
      *) info "Aborted."; exit 0 ;;
    esac
  fi

  # Remove binaries
  if [ -n "$binaries" ]; then
    while IFS= read -r bin; do
      if [ "$DRY_RUN" = true ]; then
        info "[dry-run] Would remove: $bin"
      else
        $USE_SUDO rm -f "$bin"
        info "Removed: $bin"
      fi
    done <<< "$binaries"
  fi

  # Clean store
  if [ "$CLEAN_STORE" = true ]; then
    gc_store
  fi

  # Purge if requested
  if [ "$PURGE" = true ]; then
    purge_build
  fi

  if [ "$DRY_RUN" = true ]; then
    printf "\n${YELLOW}Dry run complete — no files were removed.${RESET}\n"
  else
    printf "\n${GREEN}Uninstall complete.${RESET}\n"
  fi
}

main
