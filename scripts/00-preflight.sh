#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.sh"

log_step "Preflight checks"

run_cmd "uname -a"
run_cmd "sw_vers || true"

if [[ "$(uname)" != "Darwin" ]]; then
  log_error "This bootstrap is intended for macOS only."
  exit 1
fi

if ! has_cmd xcode-select; then
  log_warn "xcode-select not found; CLT install will be attempted in required phase"
fi

log_ok "Preflight completed"
