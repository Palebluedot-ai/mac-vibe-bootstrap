#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.sh"

log_step "Optional phase: extended tools"

for pkg in go rustup-init watch coreutils gnu-sed gawk pyenv pipx; do
  install_brew_formula "$pkg"
done

for app in arc raycast docker notion keepingyouawake stats aldente; do
  install_brew_cask "$app"
done

# Optional global npm tools from config
OPTIONAL_NPM_LIST="$ROOT_DIR/config/npm/global-packages.optional.txt"
if has_cmd npm; then
  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    if npm list -g --depth=0 "$pkg" >/dev/null 2>&1; then
      log_ok "[installed] npm global: $pkg"
    else
      run_cmd "npm install -g $pkg || true"
    fi
  done < "$OPTIONAL_NPM_LIST"
fi

# Optional Python tools from config
OPTIONAL_UV_LIST="$ROOT_DIR/config/python/uv-tools.optional.txt"
if has_cmd uv; then
  while IFS= read -r tool; do
    [[ -z "$tool" ]] && continue
    if uv tool list 2>/dev/null | grep -E "^${tool}[[:space:]]" >/dev/null; then
      log_ok "[installed] uv tool: $tool"
    else
      run_cmd "uv tool install $tool || true"
    fi
  done < "$OPTIONAL_UV_LIST"
fi

# Optional macOS defaults (safe, can customize later)
run_cmd "defaults write com.apple.finder AppleShowAllFiles -bool true"
run_cmd "defaults write NSGlobalDomain AppleShowAllExtensions -bool true"
run_cmd "killall Finder || true"

log_ok "Optional phase completed"
