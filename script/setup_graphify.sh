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

# --- drop graphify's OpenCode plugin (incompatible with OpenCode V2) ----------
# `graphify install --platform opencode` / `graphify opencode install` writes
# ~/.opencode/plugins/graphify.js in the V1 plugin shape (a named export).
# OpenCode V2 requires a default `Plugin.define({ id, setup })`, so the file
# fails to load on every start — and its opencode.json entry ("plugin" path)
# makes OpenCode try to npm-install the .js file as a package (ENOTDIR). The
# always-on guidance already lives in ~/AGENTS.md, so remove the plugin and its
# registration to keep OpenCode's log clean; the skill is unaffected.
remove_opencode_plugin() {
  local dir="$HOME/.opencode"
  [ -d "$dir" ] || return 0
  rm -f "$dir/plugins/graphify.js"

  local cfg="$dir/opencode.json"
  if [ -f "$cfg" ]; then
    if command -v jq >/dev/null 2>&1; then
      local cleaned
      cleaned="$(jq -c '.plugin = ((.plugin // []) | map(select((type == "string" and (test("graphify") | not)) or (type != "string"))))' "$cfg" 2>/dev/null || true)"
      # nothing left but the empty plugin list → drop the file entirely
      if [ -z "$cleaned" ] || [ "$cleaned" = "{}" ] || [ "$cleaned" = '{"plugin":[]}' ]; then
        rm -f "$cfg"
      else
        printf '%s\n' "$cleaned" > "$cfg"
      fi
    else
      rm -f "$cfg"
    fi
  fi

  # prune now-empty dirs graphify created (.opencode is graphify-only today)
  rmdir "$dir/plugins" "$dir" 2>/dev/null || true
  echo "Removed graphify's OpenCode plugin (V1 shape, rejected by OpenCode V2); always-on guidance stays in ~/AGENTS.md."
}

install_uv
install_graphify
register_skill
remove_opencode_plugin

echo "Graphify setup complete."
