#!/bin/bash
set -euo pipefail

OS_TYPE=$(uname)
DISTRO=""
if [ -f /etc/os-release ]; then
  . /etc/os-release
  DISTRO=$ID
fi

echo "Detected: $OS_TYPE / $DISTRO"

install_rtk() {
  if command -v rtk >/dev/null 2>&1; then
    echo "rtk already installed."
    return
  fi
  echo "Installing rtk..."
  case "$DISTRO" in
    arch|cachyos|archlabs|endeavouros|manjaro)
      if command -v paru >/dev/null 2>&1; then
        paru -S --needed --noconfirm rtk 2>/dev/null || curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
      elif command -v yay >/dev/null 2>&1; then
        yay -S --needed --noconfirm rtk 2>/dev/null || curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
      else
        curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
      fi
      ;;
    mac)
      brew install rtk 2>/dev/null || curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
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
    echo "npm not found, skipping GitNexus. Install Node first."
  fi
}

case "$DISTRO" in
  mac)
    curl -s "https://get.sdkman.io" | bash
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    install_gitnexus
    install_rtk
    ;;
  arch|cachyos|archlabs|endeavouros|manjaro)
    sudo pacman -S --needed --noconfirm base-devel python rustup
    rustup default stable
    curl -s "https://get.sdkman.io" | bash
    install_gitnexus
    install_rtk
    ;;
  debian|pop|ubuntu)
    sudo apt install -y build-essential python3
    curl -s "https://get.sdkman.io" | bash
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    install_gitnexus
    install_rtk
    ;;
  *)
    echo "Unsupported distro: $DISTRO (manual setup required)"
    echo "  - install rustup + SDKMAN + rtk + gitnexus manually"
    ;;
esac

echo "Programming environment setup complete."