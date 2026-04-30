#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.sh"

SCOPE="all" # all|required|optional
if [[ "${1:-}" == "--required" ]]; then SCOPE="required"; fi
if [[ "${1:-}" == "--optional" ]]; then SCOPE="optional"; fi

log_step "Checklist verification (scope=$SCOPE)"

required_formulas=(git wget curl jq yq ripgrep fd fzf tree htop zoxide bat eza tmux starship direnv shellcheck shfmt gh uv fnm python)
required_casks=(warp google-chrome visual-studio-code obsidian)
required_cmds=(brew git python3 uv fnm node npm pnpm gh claude codex)

optional_formulas=(go rustup-init watch coreutils gnu-sed gawk pyenv pipx)
optional_casks=(arc raycast docker notion keepingyouawake stats aldente)
optional_cmds=()

missing=0

check_formula() {
  local pkg="$1"
  local st
  st="$(brew_formula_state "$pkg")"
  if [[ "$st" == "missing" ]]; then
    log_error "[missing] brew formula: $pkg"
    missing=$((missing+1))
  else
    log_ok "[$st] brew formula: $pkg"
  fi
}

check_cask() {
  local app="$1"
  local st
  st="$(brew_cask_state "$app")"
  if [[ "$st" == "missing" ]]; then
    log_error "[missing] cask: $app"
    missing=$((missing+1))
  else
    log_ok "[$st] cask: $app"
  fi
}

check_cmd() {
  local cmd="$1"
  if has_cmd "$cmd"; then
    log_ok "[installed] command: $cmd"
  else
    log_error "[missing] command: $cmd"
    missing=$((missing+1))
  fi
}

if ! has_cmd brew; then
  log_error "brew not found; cannot run checklist"
  exit 2
fi

if [[ "$SCOPE" == "all" || "$SCOPE" == "required" ]]; then
  for p in "${required_formulas[@]}"; do check_formula "$p"; done
  for c in "${required_casks[@]}"; do check_cask "$c"; done
  for x in "${required_cmds[@]}"; do check_cmd "$x"; done
fi

if [[ "$SCOPE" == "all" || "$SCOPE" == "optional" ]]; then
  for p in "${optional_formulas[@]}"; do check_formula "$p"; done
  for c in "${optional_casks[@]}"; do check_cask "$c"; done
  for x in "${optional_cmds[@]}"; do check_cmd "$x"; done
fi

if [[ "$missing" -gt 0 ]]; then
  log_error "Checklist failed: missing items=$missing"
  exit 1
fi

log_ok "Checklist passed: all selected items installed"
