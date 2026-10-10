#!/usr/bin/env bash
# setup_graphify.sh - install the graphify CLI and register its agent skill.
#
# graphify (https://github.com/Graphify-Labs/graphify) is a Python CLI published
# on PyPI as `graphifyy` (double-y); the installed command is `graphify`. It is
# provisioned with uv (Python tool runner), which is itself installed via mise
# alongside the other toolchains. `graphify install --platform <p>` writes the
# /graphify skill into that agent's user-scope skill directory.
#
# Usage:
#   bash setup_graphify.sh            # install uv + graphifyy + register skill (idempotent)
#
# Requires: mise in PATH (arch: pacman, mac: brew, other: the mise installer).

set -euo pipefail

# uv installs tool shims into ~/.local/bin, which the dotfiles zsh puts on PATH;
# bootstrap may run from a plain shell, so add it explicitly here too.
export PATH="$HOME/.local/bin:$PATH"

# --- uv (Python tool runner) via mise ----------------------------------------
install_uv() {
  if command -v uv >/dev/null 2>&1; then
    echo "uv already available."
    return
  fi
  echo "Installing uv via mise..."
  # `use -g` records the tool in mise's global config and installs it.
  mise use -g uv@latest
}

# uv_cmd — run uv, falling back to mise's environment when uv is not directly on
# PATH (a fresh shell may not have mise's shims activated yet).
uv_cmd() {
  if command -v uv >/dev/null 2>&1; then
    uv "$@"
  else
    mise exec -- uv "$@"
  fi
}

# --- graphify CLI (PyPI: graphifyy) -----------------------------------------
install_graphify() {
  if command -v graphify >/dev/null 2>&1; then
    echo "graphify already installed."
    return
  fi
  echo "Installing graphify (graphifyy)..."
  uv_cmd tool install graphifyy
}

# --- register the /graphify skill with the AI assistants ---------------------
register_skill() {
  if ! command -v graphify >/dev/null 2>&1; then
    echo "warning: graphify not on PATH; skipping skill registration."
    echo "         open a new shell and re-run, or run 'uv tool update-shell'."
    return
  fi
  # One platform per call (graphify accepts --platform only once). opencode's
  # always-on plugin is written to ./.opencode, so run from $HOME: it lands at
  # ~/.opencode (a discovery ancestor of every project) rather than inside a
  # project checkout such as this repo.
  local platform
  for platform in opencode claude codex agents; do
    echo "Registering graphify skill: $platform"
    ( cd "$HOME" && graphify install --platform "$platform" ) >/dev/null 2>&1 \
      || echo "warning: 'graphify install --platform $platform' failed; continuing"
  done

  # opencode has a dedicated always-on command on top of the skill: it writes an
  # AGENTS.md instruction block plus the tool.execute.before plugin, so the
  # assistant consults the graph before answering codebase questions. Again run
  # from $HOME so both land at the home root (~/AGENTS.md, ~/.opencode), which is
  # a discovery ancestor of every project, rather than inside a checkout.
  echo "Enabling graphify always-on for opencode"
  ( cd "$HOME" && graphify opencode install ) >/dev/null 2>&1 \
    || echo "warning: 'graphify opencode install' failed; continuing"
}

install_uv
install_graphify
register_skill

echo "Graphify setup complete."
