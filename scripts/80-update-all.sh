#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.sh"

log_step "Update phase"

if has_cmd brew; then
  run_cmd "brew update"
  run_cmd "brew upgrade"
  run_cmd "brew upgrade --cask || true"
  run_cmd "brew cleanup"
fi

if has_cmd uv; then
  run_cmd "uv self update || true"
fi

if has_cmd npm; then
  run_cmd "npm -g update || true"
fi

if has_cmd gh; then
  run_cmd "gh extension upgrade --all || true"
fi

log_ok "Update phase completed"
