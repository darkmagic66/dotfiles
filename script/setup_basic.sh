#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# DISTRO is normally exported by install.sh; fall back to local detect when
# run standalone.
if [ -z "${DISTRO:-}" ]; then
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO="$ID"
  elif [ "$(uname)" == "Darwin" ]; then
    DISTRO="mac"
  else
    echo "Usage: ./setup_basic.sh   (or set \$DISTRO=mac|debian|arch|cachyos|fedora)"
    exit 1
  fi
fi

# Packages available on all OSes via their native package managers.
COMMON_PACKAGES=(
  tmux
  htop
  fd
  fzf
  zoxide
  bat
  ripgrep
  jq
  neovim
  git
  stow
  zsh
  zip
  unzip
  curl
  wget
  git-delta
  eza
  kitty
  tree-sitter-cli
)

install_mac() {
  command -v brew >/dev/null 2>&1 || {
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  }
  brew update
  brew install "${COMMON_PACKAGES[@]}" tldr asciinema
}

install_debian() {
  sudo apt update
  # eza is not in older Ubuntu/Pop!_OS repos — install from official deb repo
  if ! command -v eza >/dev/null 2>&1; then
    echo "Installing eza from upstream deb repo..."
    sudo mkdir -p /etc/apt/keyrings
    sudo wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
      | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
      | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  fi
  sudo apt install -y "${COMMON_PACKAGES[@]}" eza fd-find tldr asciinema python3 build-essential
}

install_arch() {
  sudo pacman -Syu --noconfirm "${COMMON_PACKAGES[@]}"
}

install_fedora() {
  sudo dnf install -y "${COMMON_PACKAGES[@]}" tldr asciinema
}

case "$DISTRO" in
  mac)
    install_mac
    ;;
  debian|pop|ubuntu)
    install_debian
    ;;
  arch|cachyos|archlabs|endeavouros|manjaro)
    install_arch
    ;;
  fedora)
    install_fedora
    ;;
  *)
    echo "Unsupported OS/Distro: $DISTRO"
    exit 1
    ;;
esac

# --- Distro-specific extras (extensions are self-guarded) -------------------
# setup_os/<distro>.sh files install distro-only packages (wayne, vscode, etc)
# and run distro-only service / config steps. Each file is a no-op if $DISTRO
# doesn't match it, so the glob is safe to source unconditionally.
echo "Loading distro-specific extensions..."
for f in "$SCRIPT_DIR"/setup_os/*.sh; do
  [ -f "$f" ] || continue
  # shellcheck disable=SC1090
  source "$f"
done

echo "Base packages installed successfully."
