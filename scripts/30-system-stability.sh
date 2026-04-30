#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.sh"

MODE="apply" # apply|status|restore
if [[ "${1:-}" == "--status" ]]; then MODE="status"; fi
if [[ "${1:-}" == "--restore" ]]; then MODE="restore"; fi

log_step "System stability profile ($MODE)"

if [[ "$MODE" == "status" ]]; then
  run_cmd "pmset -g custom"
  run_cmd "pmset -g batt"
  run_cmd "pmset -g assertions"
  exit 0
fi

if [[ "$MODE" == "restore" ]]; then
  log_warn "Restoring conservative defaults"
  run_cmd "sudo pmset -c sleep 10"
  run_cmd "sudo pmset -b sleep 10"
  run_cmd "sudo pmset -a displaysleep 10"
  run_cmd "sudo pmset -a disksleep 10"
  run_cmd "sudo pmset -a womp 1"
  run_cmd "sudo pmset -a powernap 1 || true"
  log_ok "Defaults restored"
  exit 0
fi

# apply profile for vibe coding stability
log_info "Applying anti-sleep + background-stable profile"
run_cmd "sudo pmset -c sleep 0"
run_cmd "sudo pmset -c displaysleep 20"
run_cmd "sudo pmset -c disksleep 0"
run_cmd "sudo pmset -a womp 1"
run_cmd "sudo pmset -a tcpkeepalive 1"
run_cmd "sudo pmset -a powernap 1 || true"

# helper launch agent template for long-running keepawake (user can enable if needed)
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

log_ok "Wrote launch agent template: $LAUNCH_AGENT_FILE"
log_info "Enable when needed: launchctl load -w $LAUNCH_AGENT_FILE"
log_info "Disable: launchctl unload -w $LAUNCH_AGENT_FILE"

log_ok "System stability profile applied"
