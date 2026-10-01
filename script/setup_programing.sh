#!/usr/bin/env bash
# setup_programing.sh - install language toolchains via mise + utilities.
#
# mise manages all language runtimes (go, java, node, rust) from mise.toml.
# This replaces the old approach of separate fnm/rustup/SDKMAN installers.
#
# Usage:
#   bash setup_programing.sh            # install everything (idempotent)
#
# Requires: mise in PATH (arch: pacman, mac: brew, other: installed below).

set -euo pipefail

# DISTRO is normally exported by install.sh; fall back to local detect when
# run standalone.
if [ -z "${DISTRO:-}" ]; then
  if [ "$(uname)" == "Darwin" ]; then
    DISTRO="mac"
  elif [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO="$ID"
  fi
fi

echo "Detected: $(uname) / ${DISTRO:-unknown}"

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

# --- mise (language runtime manager) ----------------------------------------
install_mise() {
  if command -v mise >/dev/null 2>&1; then
    echo "mise already installed."
    return
  fi
  echo "Installing mise..."
  case "${DISTRO:-}" in
    mac)
      brew install mise
      ;;
    arch|cachyos|archlabs|endeavouros|manjaro)
      sudo pacman -S --needed --noconfirm mise
      ;;
    *)
      curl -fsSL https://mise.run | sh
      ;;
  esac
}

# --- language toolchains (go, java, node, rust) via mise.toml ---------------
install_toolchains() {
  echo "Installing language toolchains via mise..."
  mise install
}

# --- gitnexus (npm global, needs node from mise) ----------------------------
install_gitnexus() {
  if mise exec -- gitnexus --version >/dev/null 2>&1; then
    echo "GitNexus already installed."
    return
  fi
  echo "Installing GitNexus..."
  mise exec -- npm install -g gitnexus
}

# --- rtk (CLI proxy, not a language runtime) --------------------------------
install_rtk() {
  if command -v rtk >/dev/null 2>&1; then
    echo "rtk already installed."
    return
  fi
  echo "Installing rtk..."
  case "${DISTRO:-}" in
    arch|cachyos|archlabs|endeavouros|manjaro)
      if command -v paru >/dev/null 2>&1; then
        paru -S --needed --noconfirm rtk 2>/dev/null \
          || curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
      elif command -v yay >/dev/null 2>&1; then
        yay -S --needed --noconfirm rtk 2>/dev/null \
          || curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
      else
        curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
      fi
      ;;
    mac)
      brew install rtk 2>/dev/null \
        || curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
      ;;
    *)
      curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
      ;;
  esac
}

install_mise
install_toolchains
install_gitnexus
install_rtk

echo "Programming environment setup complete."
