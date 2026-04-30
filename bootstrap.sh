#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$ROOT_DIR/scripts"
LOG_DIR="$ROOT_DIR/logs"
mkdir -p "$LOG_DIR"

BOOTSTRAP_DRY_RUN=0
MODE="all"       # all|required|optional|update
ONLY=""
SKIP=""

usage() {
  cat <<'EOF'
Usage:
  bash bootstrap.sh [options]

Options:
  --required           Run required part only
  --optional           Run optional part only
  --update             Update installed tools only
  --only <module>      Run only one module (preflight|required|optional|stability|postcheck|update)
  --skip <module>      Skip one module
  --dry-run            Show what would run without executing
  -h, --help           Show help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --required) MODE="required"; shift ;;
    --optional) MODE="optional"; shift ;;
    --update) MODE="update"; shift ;;
    --only) ONLY="${2:-}"; shift 2 ;;
    --skip) SKIP="${2:-}"; shift 2 ;;
    --dry-run) BOOTSTRAP_DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

source "$SCRIPTS_DIR/lib.sh"
init_logging "$LOG_DIR"
set_dry_run "$BOOTSTRAP_DRY_RUN"
export DRY_RUN LOG_FILE

run_module() {
  local key="$1"
  local path="$2"

  if [[ -n "$ONLY" && "$ONLY" != "$key" ]]; then
    log_info "[SKIP] $key (only=$ONLY)"
    return
  fi

  if [[ -n "$SKIP" && "$SKIP" == "$key" ]]; then
    log_info "[SKIP] $key (skip=$SKIP)"
    return
  fi

  log_step "Running module: $key"
  run_cmd "bash '$path'"
}

log_info "Mode=$MODE dry_run=$BOOTSTRAP_DRY_RUN"
run_module "preflight" "$SCRIPTS_DIR/00-preflight.sh"

case "$MODE" in
  all)
    run_module "required" "$SCRIPTS_DIR/10-required.sh"
    run_module "optional" "$SCRIPTS_DIR/20-optional.sh"
    run_module "stability" "$SCRIPTS_DIR/30-system-stability.sh"
    run_module "postcheck" "$SCRIPTS_DIR/70-post-check.sh"
    ;;
  required)
    run_module "required" "$SCRIPTS_DIR/10-required.sh"
    run_module "stability" "$SCRIPTS_DIR/30-system-stability.sh"
    run_module "postcheck" "$SCRIPTS_DIR/70-post-check.sh"
    ;;
  optional)
    run_module "optional" "$SCRIPTS_DIR/20-optional.sh"
    run_module "stability" "$SCRIPTS_DIR/30-system-stability.sh"
    run_module "postcheck" "$SCRIPTS_DIR/70-post-check.sh"
    ;;
  update)
    run_module "update" "$SCRIPTS_DIR/80-update-all.sh"
    run_module "postcheck" "$SCRIPTS_DIR/70-post-check.sh"
    ;;
  *)
    log_error "Invalid mode: $MODE"; exit 1 ;;
esac

log_ok "Bootstrap finished successfully"
