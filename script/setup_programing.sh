#!/bin/bash -e

OS_TYPE=$(uname)
DISTRO=""
if [ -f /etc/os-release ]; then
  . /etc/os-release
  DISTRO=$ID
fi

echo "Detected: $OS_TYPE / $DISTRO"

case "$DISTRO" in
  mac)
    # SDKMAN (kept on all OSes per user preference)
    curl -s "https://get.sdkman.io" | bash
    # Rust via rustup script
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    ;;
  arch|cachyos|archlabs|endeavouros|manjaro)
    sudo pacman -S --needed --noconfirm base-devel python rustup
    # Rust via pacman-provided rustup
    rustup default stable
    # SDKMAN (kept on all OSes per user preference)
    curl -s "https://get.sdkman.io" | bash
    ;;
  debian|pop|ubuntu)
    sudo apt install -y build-essential python3
    curl -s "https://get.sdkman.io" | bash
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    ;;
  *)
    echo "Unsupported distro: $DISTRO (manual setup required)"
    echo "  - install rustup + SDKMAN manually"
    ;;
esac

echo "Programming environment setup complete."