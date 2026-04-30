#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.sh"

log_step "Post-check: versions and health"

for cmd in brew git python3 uv fnm node npm pnpm gh claude codex; do
  if has_cmd "$cmd"; then
    ver="$($cmd --version 2>/dev/null | head -n 1 || true)"
    log_ok "[ok] $cmd => $ver"
  else
    log_warn "[missing] $cmd"
  fi
done

if has_cmd brew; then
  log_info "Outdated packages (if any):"
  run_cmd "brew outdated || true"
fi

log_ok "Post-check completed"
