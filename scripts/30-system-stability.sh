#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.sh"

MODE="apply" # apply|status|restore
if [[ "${1:-}" == "--status" ]]; then MODE="status"; fi
if [[ "${1:-}" == "--restore" ]]; then MODE="restore"; fi

log_step "System stability profile ($MODE)"

SUDO_OK=0
if sudo -n true >/dev/null 2>&1; then
  SUDO_OK=1
else
  log_warn "No sudo TTY in this session; pmset/xcode privileged steps will be skipped. Run locally in terminal to apply fully."
fi

run_pmset() {
  local cmd="$1"
  if [[ "$SUDO_OK" == "1" ]]; then
    run_cmd "sudo $cmd"
  else
    log_warn "[skip] sudo $cmd"
  fi
}

if [[ "$MODE" == "status" ]]; then
  run_cmd "pmset -g custom"
  run_cmd "pmset -g batt"
  run_cmd "pmset -g assertions"
  exit 0
fi

if [[ "$MODE" == "restore" ]]; then
  log_warn "Restoring conservative defaults"
  run_pmset "pmset -c sleep 10"
  run_pmset "pmset -b sleep 10"
  run_pmset "pmset -a displaysleep 10"
  run_pmset "pmset -a disksleep 10"
  run_pmset "pmset -a womp 1"
  run_pmset "pmset -a powernap 1"
  log_ok "Defaults restored"
  exit 0
fi

# apply profile for vibe coding stability
log_info "Applying anti-sleep + background-stable profile"
run_pmset "pmset -c sleep 0"
run_pmset "pmset -c displaysleep 20"
run_pmset "pmset -c disksleep 0"
run_pmset "pmset -a womp 1"
run_pmset "pmset -a tcpkeepalive 1"
run_pmset "pmset -a powernap 1"

# launch agent for long-running keepawake (auto-enable on new machine)
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_FILE="$LAUNCH_AGENT_DIR/com.vibecoding.keepawake.plist"
run_cmd "mkdir -p '$LAUNCH_AGENT_DIR'"
cat > "$LAUNCH_AGENT_FILE" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key><string>com.vibecoding.keepawake</string>
    <key>ProgramArguments</key>
    <array>
      <string>/usr/bin/caffeinate</string>
      <string>-dimsu</string>
    </array>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><true/>
    <key>ProcessType</key><string>Background</string>
    <key>StandardOutPath</key><string>/tmp/com.vibecoding.keepawake.out</string>
    <key>StandardErrorPath</key><string>/tmp/com.vibecoding.keepawake.err</string>
  </dict>
</plist>
PLIST

run_cmd "launchctl unload -w '$LAUNCH_AGENT_FILE' >/dev/null 2>&1 || true"
run_cmd "launchctl load -w '$LAUNCH_AGENT_FILE'"
log_ok "Keepawake launch agent loaded: $LAUNCH_AGENT_FILE"

# app-level stability defaults / startup behavior
if has_cmd defaults; then
  run_cmd "defaults write de.marcoisser.keepingyouawake StartAtLogin -bool true || true"
  run_cmd "defaults write de.marcoisser.keepingyouawake RestoreState -bool true || true"
  run_cmd "defaults write eu.exelban.Stats runAtLogin -bool true || true"
fi

# add key apps to macOS Login Items (idempotent)
if has_cmd osascript; then
  ensure_login_item() {
    local app_name="$1"
    local app_path="$2"
    run_cmd "osascript -e 'with timeout of 5 seconds' -e 'tell application \"System Events\" to delete login item \"${app_name}\"' -e 'end timeout' || true"
    run_cmd "osascript -e 'with timeout of 5 seconds' -e 'tell application \"System Events\" to make login item at end with properties {name:\"${app_name}\",path:\"${app_path}\", hidden:false}' -e 'end timeout' || true"
  }

  ensure_login_item "Stats" "/Applications/Stats.app"
  ensure_login_item "KeepingYouAwake" "/Applications/KeepingYouAwake.app"
  ensure_login_item "AlDente" "/Applications/AlDente.app"
fi

log_ok "System stability profile applied"
