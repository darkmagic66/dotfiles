#!/usr/bin/env bash
# setup_pi.sh - install the Pi coding agent CLI (earendil-works/pi).
#
# Pi (https://github.com/earendil-works/pi) is a minimal, extensible agent
# harness published to npm as @earendil-works/pi-coding-agent, which installs
# the `pi` command. It requires Node.js 22.19+; node comes from mise.toml.
# The npm route is used because Pi is not packaged for apt/dnf and upstream
# does not publish the Homebrew formula (the core formula is third-party).
#
# Usage:
#   bash setup_pi.sh            # install CLI (idempotent)
#
# Requires: mise in PATH (arch: pacman, mac: brew, other: the mise installer).
# Authenticate after install by running `pi` and then `/login`.

set -euo pipefail

# mise installs node's global npm bin under its own tree; the dotfiles zsh puts
# mise's shims on PATH, but bootstrap may run from a plain shell.
export PATH="$HOME/.local/bin:$PATH"

# --- pi CLI (npm: @earendil-works/pi-coding-agent) --------------------------
install_pi() {
  if command -v pi >/dev/null 2>&1 || mise exec -- pi --version >/dev/null 2>&1; then
    echo "pi already installed."
    return
  fi
  echo "Installing Pi coding agent..."
  # node comes from mise.toml (installed by setup_programing.sh).
  mise exec -- npm install -g @earendil-works/pi-coding-agent
}

install_pi

echo "Pi setup complete."
echo "Authenticate on first run:  pi   (then /login)"
