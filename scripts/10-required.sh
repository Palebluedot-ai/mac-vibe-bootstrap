#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.sh"

log_step "Required phase: system + core dev tools"

# 1) Xcode CLT
if xcode-select -p >/dev/null 2>&1; then
  log_ok "[installed] Xcode Command Line Tools"
else
  log_info "Installing Xcode Command Line Tools (GUI prompt may appear)"
  run_cmd "xcode-select --install || true"
  log_warn "If CLT dialog appeared, complete it and re-run bootstrap.sh"
fi

# 2) Homebrew
if has_cmd brew; then
  log_ok "[installed] Homebrew"
else
  log_info "Installing Homebrew"
  run_cmd '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  append_if_missing "$HOME/.zprofile" 'eval "$(/opt/homebrew/bin/brew shellenv)"'
  run_cmd 'eval "$(/opt/homebrew/bin/brew shellenv)"'
fi

# 3) Core formulas
for pkg in git wget curl jq yq ripgrep fd fzf tree htop zoxide bat eza tmux starship direnv shellcheck shfmt gh uv fnm; do
  install_brew_formula "$pkg"
done

# 4) Python
install_brew_formula python
log_ok "python3 active: $(python3 --version 2>/dev/null || true)"

# 5) Node via FNM
if has_cmd fnm; then
  append_if_missing "$HOME/.zshrc" 'eval "$(fnm env --use-on-cd --shell zsh)"'
  run_cmd 'eval "$(fnm env --use-on-cd --shell bash)"; fnm install --lts; fnm default lts-latest'
else
  log_error "fnm not available after install"
fi

# 6) npm global tools from config
REQUIRED_NPM_LIST="$ROOT_DIR/config/npm/global-packages.required.txt"
if has_cmd npm; then
  log_ok "[installed] npm: $(npm -v 2>/dev/null || true)"
  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    if npm list -g --depth=0 "$pkg" >/dev/null 2>&1; then
      log_ok "[installed] npm global: $pkg"
    else
      run_cmd "npm install -g $pkg || true"
    fi
  done < "$REQUIRED_NPM_LIST"
else
  log_warn "npm not found (likely shell not reloaded). Re-run bootstrap after opening new terminal."
fi

# 7) Essential casks
for app in warp google-chrome visual-studio-code obsidian; do
  install_brew_cask "$app"
done

# 8) Xcode first-launch and license (safe if already done)
if sudo -n true >/dev/null 2>&1; then
  run_cmd "sudo xcodebuild -license accept || true"
  run_cmd "sudo xcodebuild -runFirstLaunch || true"
else
  log_warn "No sudo TTY; skip xcodebuild privileged init in this session. Run locally: sudo xcodebuild -license accept && sudo xcodebuild -runFirstLaunch"
fi

# 9) Claude Code + Codex executable validation (non-blocking)
for cli in claude codex; do
  if has_cmd "$cli"; then
    ver="$($cli --version 2>/dev/null | head -n 1 || true)"
    log_ok "[ready] $cli => ${ver:-version unknown}"
  else
    log_warn "[not_ready] $cli not found in PATH (install may have failed or shell not reloaded)"
  fi
done

log_ok "Required phase completed"
