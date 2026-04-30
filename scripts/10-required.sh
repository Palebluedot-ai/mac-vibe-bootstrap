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
if has_cmd python3; then
  log_ok "[installed] python3: $(python3 --version 2>/dev/null || true)"
else
  install_brew_formula python
fi

# 5) Node via FNM
if has_cmd fnm; then
  append_if_missing "$HOME/.zshrc" 'eval "$(fnm env --use-on-cd --shell zsh)"'
  run_cmd 'eval "$(fnm env --use-on-cd --shell zsh)"; fnm install --lts; fnm default lts-latest'
else
  log_error "fnm not available after install"
fi

# 6) npm & pnpm
if has_cmd npm; then
  log_ok "[installed] npm: $(npm -v 2>/dev/null || true)"
  run_cmd "npm install -g pnpm typescript tsx eslint prettier"
else
  log_warn "npm not found (likely shell not reloaded). Re-run bootstrap after opening new terminal."
fi

# 7) Essential casks
for app in warp google-chrome visual-studio-code obsidian; do
  install_brew_cask "$app"
done

# 8) Xcode first-launch and license (safe if already done)
run_cmd "sudo xcodebuild -license accept || true"
run_cmd "sudo xcodebuild -runFirstLaunch || true"

# 9) Claude Code + Codex install placeholders
log_info "Installing Claude Code and Codex CLI (best-effort)"
run_cmd "npm install -g @anthropic-ai/claude-code || true"
run_cmd "npm install -g @openai/codex || true"

log_ok "Required phase completed"
