#!/bin/bash
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

install_fnm() {
  if command -v fnm >/dev/null 2>&1; then
    echo "fnm already installed."
    return
  fi
  echo "Installing fnm..."
  case "${DISTRO:-}" in
    mac)
      brew install fnm
      ;;
    arch|cachyos|archlabs|endeavouros|manjaro)
      sudo pacman -S --needed --noconfirm fnm
      ;;
    *)
      curl -fsSL https://fnm.vercel.app/install | bash
      ;;
  esac
  # Best-effort: provision a default Node so `npm` (for gitnexus) is on PATH.
  if command -v fnm >/dev/null 2>&1; then
    fnm install --latest 2>/dev/null || true
    # eval the env so subsequent commands in this script see node/npm
    eval "$(fnm env 2>/dev/null)" || true
  fi
}

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

install_gitnexus() {
  if command -v gitnexus >/dev/null 2>&1; then
    echo "GitNexus already installed."
    return
  fi
  if command -v npm >/dev/null 2>&1; then
    echo "Installing GitNexus..."
    npm install -g gitnexus
  else
    echo "npm not found, skipping GitNexus. Install Node first (fnm runs in setup_programing.sh)."
  fi
}

case "${DISTRO:-}" in
  mac)
    install_fnm
    curl -s "https://get.sdkman.io" | bash
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    install_gitnexus
    install_rtk
    ;;
  arch|cachyos|archlabs|endeavouros|manjaro)
    sudo pacman -S --needed --noconfirm base-devel python rustup
    rustup default stable
    install_fnm
    curl -s "https://get.sdkman.io" | bash
    install_gitnexus
    install_rtk
    ;;
  debian|pop|ubuntu)
    sudo apt install -y build-essential python3
    install_fnm
    curl -s "https://get.sdkman.io" | bash
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    install_gitnexus
    install_rtk
    ;;
  *)
    # fallback: try curl installers (no distro packages)
    install_fnm
    curl -s "https://get.sdkman.io" | bash || true
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || true
    install_gitnexus
    install_rtk
    ;;
esac

echo "Programming environment setup complete."