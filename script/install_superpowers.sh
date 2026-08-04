#!/usr/bin/env bash
# Install the superpowers framework for one or more coding agents.
# Usage: ./install_superpowers.sh [agent ...]
# Agents: opencode claude copilot antigravity codex cursor droid kimi pi
# No args = install for every agent whose CLI is detected on PATH.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info() { printf '\033[1;34m[install]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[ok]\033[0m      %s\n' "$*"; }
warn() { printf '\033[1;33m[skip]\033[0m    %s\n' "$*"; }
err()  { printf '\033[1;31m[err]\033[0m     %s\n' "$*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

install_opencode() {
  info "opencode: managed by dotfile (~/dotfiles/opencode/.config/opencode/opencode.jsonc)"
  if grep -q "superpowers@git" "$HOME/.config/opencode/opencode.jsonc" 2>/dev/null; then
    ok "plugin spec already present; just restart opencode"
  else
    err "opencode.jsonc missing superpowers plugin spec — check the opencode stow package"
    return 1
  fi
}

install_claude() {
  if ! have claude; then
    warn "claude: CLI not found on PATH"; return 0
  fi
  info "claude: running /plugin install"
  claude plugin install superpowers@claude-plugins-official
  ok "claude: installed"
}

install_copilot() {
  if ! have copilot; then
    warn "copilot: CLI not found on PATH"; return 0
  fi
  info "copilot: registering marketplace and installing plugin"
  copilot plugin marketplace add obra/superpowers-marketplace
  copilot plugin install superpowers@superpowers-marketplace
  ok "copilot: installed"
}

install_antigravity() {
  if ! have agy; then
    warn "antigravity (agy): CLI not found on PATH"; return 0
  fi
  info "antigravity: installing plugin from repo"
  agy plugin install https://github.com/obra/superpowers
  ok "antigravity: installed"
}

install_codex() {
  warn "codex: requires interactive /plugins inside the Codex CLI — open Codex and run: /plugins → search 'superpowers' → install"
}

install_cursor() {
  warn "cursor: requires interactive /add-plugin in Cursor Agent chat — run: /add-plugin superpowers"
}

install_droid() {
  if ! have droid; then
    warn "droid: CLI not found on PATH"; return 0
  fi
  info "droid: registering marketplace and installing plugin"
  droid plugin marketplace add https://github.com/obra/superpowers
  droid plugin install superpowers@superpowers
  ok "droid: installed"
}

install_kimi() {
  warn "kimi: requires interactive /plugins inside Kimi Code — open Kimi and run: /plugins → Marketplace → Superpowers"
}

install_pi() {
  if ! have pi; then
    warn "pi: CLI not found on PATH"; return 0
  fi
  info "pi: installing package from repo"
  pi install git:github.com/obra/superpowers
  ok "pi: installed"
}

declare -A HANDLERS=(
  [opencode]=install_opencode
  [claude]=install_claude
  [copilot]=install_copilot
  [antigravity]=install_antigravity
  [codex]=install_codex
  [cursor]=install_cursor
  [droid]=install_droid
  [kimi]=install_kimi
  [pi]=install_pi
)

if [ $# -eq 0 ]; then
  info "no agent specified; running all handlers (each skips if its CLI is missing)"
  for agent in "${!HANDLERS[@]}"; do
    "${HANDLERS[$agent]}" || true
  done
  exit 0
fi

for agent in "$@"; do
  if [ -z "${HANDLERS[$agent]+set}" ]; then
    err "unknown agent: $agent (supported: ${!HANDLERS[*]})"
    exit 1
  fi
  "${HANDLERS[$agent]}" || true
done
