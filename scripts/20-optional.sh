#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.sh"

log_step "Optional phase: extended tools"

for pkg in go rustup-init watch coreutils gnu-sed gawk pyenv pipx; do
  install_brew_formula "$pkg"
done

for app in arc raycast docker notion; do
  install_brew_cask "$app"
done

# Optional global npm tools
if has_cmd npm; then
  run_cmd "npm install -g npm-check-updates yarn"
fi

# Optional Python tools
if has_cmd uv; then
  run_cmd "uv tool install ruff || true"
  run_cmd "uv tool install black || true"
  run_cmd "uv tool install mypy || true"
  run_cmd "uv tool install pytest || true"
fi

# Optional macOS defaults (safe, can customize later)
run_cmd "defaults write com.apple.finder AppleShowAllFiles -bool true"
run_cmd "defaults write NSGlobalDomain AppleShowAllExtensions -bool true"
run_cmd "killall Finder || true"

log_ok "Optional phase completed"
