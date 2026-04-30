#!/usr/bin/env bash
set -euo pipefail

DRY_RUN="${DRY_RUN:-0}"
LOG_FILE="${LOG_FILE:-}"

C_RESET='\033[0m'
C_BLUE='\033[1;34m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_RED='\033[1;31m'

init_logging() {
  local log_dir="$1"
  mkdir -p "$log_dir"
  LOG_FILE="$log_dir/bootstrap-$(date +%Y%m%d-%H%M%S).log"
  touch "$LOG_FILE"
  log_info "Log file: $LOG_FILE"
}

set_dry_run() {
  DRY_RUN="$1"
}

_ts() { date +"%F %T"; }

_log() {
  local level="$1"; shift
  local msg="$*"
  echo "[$(_ts)] [$level] $msg" | tee -a "$LOG_FILE"
}

log_info() { echo -e "${C_BLUE}$*${C_RESET}"; _log INFO "$*"; }
log_ok() { echo -e "${C_GREEN}$*${C_RESET}"; _log OK "$*"; }
log_warn() { echo -e "${C_YELLOW}$*${C_RESET}"; _log WARN "$*"; }
log_error() { echo -e "${C_RED}$*${C_RESET}"; _log ERROR "$*"; }
log_step() { log_info "==== $* ===="; }

run_cmd() {
  local cmd="$1"
  if [[ "$DRY_RUN" == "1" ]]; then
    log_info "[DRY-RUN] $cmd"
    return 0
  fi
  bash -lc "$cmd" 2>&1 | tee -a "$LOG_FILE"
}

has_cmd() { command -v "$1" >/dev/null 2>&1; }

# Return 0 if package appears in brew outdated list
is_brew_outdated() {
  local name="$1"
  brew outdated --quiet | grep -Fxq "$name"
}

brew_formula_state() {
  local pkg="$1"
  if ! brew list "$pkg" >/dev/null 2>&1; then
    echo "missing"
  elif is_brew_outdated "$pkg"; then
    echo "installed_outdated"
  else
    echo "installed_latest"
  fi
}

brew_cask_state() {
  local app="$1"
  if ! brew list --cask "$app" >/dev/null 2>&1; then
    echo "missing"
  elif is_brew_outdated "$app"; then
    echo "installed_outdated"
  else
    echo "installed_latest"
  fi
}

install_brew_formula() {
  local pkg="$1"
  local state
  state="$(brew_formula_state "$pkg")"
  case "$state" in
    installed_latest)
      log_ok "[installed_latest] brew formula: $pkg"
      ;;
    installed_outdated)
      log_warn "[installed_outdated] brew formula: $pkg (run --update to upgrade)"
      ;;
    missing)
      log_info "Installing brew formula: $pkg"
      run_cmd "brew install $pkg"
      ;;
  esac
}

install_brew_cask() {
  local app="$1"
  local state
  state="$(brew_cask_state "$app")"
  case "$state" in
    installed_latest)
      log_ok "[installed_latest] cask: $app"
      ;;
    installed_outdated)
      log_warn "[installed_outdated] cask: $app (run --update to upgrade)"
      ;;
    missing)
      log_info "Installing cask: $app"
      run_cmd "brew install --cask $app"
      ;;
  esac
}

append_if_missing() {
  local file="$1"
  local line="$2"
  touch "$file"
  if grep -Fq "$line" "$file"; then
    log_ok "[exists] $line"
  else
    run_cmd "printf '%s\n' '$line' >> '$file'"
    log_ok "[added] $line"
  fi
}
