#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.sh"

REPORT_DIR="$ROOT_DIR/logs"
mkdir -p "$REPORT_DIR"
REPORT_FILE="$REPORT_DIR/final-report-$(date +%Y%m%d-%H%M%S).md"

required_cmds=(brew git python3 uv fnm node npm pnpm gh claude codex)
optional_cmds=(docker go rustup)

required_formulas=(git wget curl jq yq ripgrep fd fzf tree htop zoxide bat eza tmux starship direnv shellcheck shfmt gh uv fnm python)
required_casks=(warp google-chrome visual-studio-code obsidian)
optional_formulas=(go rustup-init watch coreutils gnu-sed gawk pyenv pipx)
optional_casks=(arc raycast docker notion keepingyouawake stats aldente)

count_missing=0
count_outdated=0

emit_state() {
  local kind="$1" name="$2" st="$3"
  echo "- [$kind] $name => $st" >> "$REPORT_FILE"
  if [[ "$st" == "missing" && "$kind" == required* ]]; then
    count_missing=$((count_missing+1))
  fi
  if [[ "$st" == "installed_outdated" ]]; then
    count_outdated=$((count_outdated+1))
  fi
  return 0
}

{
  echo "# Mac Vibe Bootstrap Final Report"
  echo
  echo "- Generated: $(date '+%F %T %Z')"
  echo "- Host: $(hostname)"
  echo "- OS: $(sw_vers -productName) $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
  echo
  echo "## Command Availability"
} > "$REPORT_FILE"

for c in "${required_cmds[@]}"; do
  if has_cmd "$c"; then
    v="$($c --version 2>/dev/null | head -n 1 || true)"
    echo "- [required] $c => installed (${v:-unknown})" >> "$REPORT_FILE"
  else
    echo "- [required] $c => missing" >> "$REPORT_FILE"
    count_missing=$((count_missing+1))
  fi
done
for c in "${optional_cmds[@]}"; do
  if has_cmd "$c"; then
    v="$($c --version 2>/dev/null | head -n 1 || true)"
    echo "- [optional] $c => installed (${v:-unknown})" >> "$REPORT_FILE"
  else
    echo "- [optional] $c => missing" >> "$REPORT_FILE"
  fi
done

echo >> "$REPORT_FILE"
echo "## Brew Formula/Cask State" >> "$REPORT_FILE"
for p in "${required_formulas[@]}"; do emit_state "required formula" "$p" "$(brew_formula_state "$p")"; done
for p in "${optional_formulas[@]}"; do emit_state "optional formula" "$p" "$(brew_formula_state "$p")"; done
for c in "${required_casks[@]}"; do emit_state "required cask" "$c" "$(brew_cask_state "$c")"; done
for c in "${optional_casks[@]}"; do emit_state "optional cask" "$c" "$(brew_cask_state "$c")"; done

echo >> "$REPORT_FILE"
echo "## Power / Stability Snapshot" >> "$REPORT_FILE"
{
  echo "\`\`\`"
  pmset -g custom || true
  echo
  pmset -g batt || true
  echo
  pmset -g assertions || true
  echo "\`\`\`"
} >> "$REPORT_FILE"

echo >> "$REPORT_FILE"
echo "## Summary" >> "$REPORT_FILE"
echo "- Missing required items: $count_missing" >> "$REPORT_FILE"
echo "- Outdated items: $count_outdated" >> "$REPORT_FILE"

if [[ "$count_missing" -eq 0 ]]; then
  echo "- Verdict: ✅ Ready for Vibe Coding" >> "$REPORT_FILE"
else
  echo "- Verdict: ⚠️ Not fully ready (missing required items)" >> "$REPORT_FILE"
fi

log_ok "Final report generated: $REPORT_FILE"
cat "$REPORT_FILE"
