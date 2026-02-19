#!/bin/bash -e

DISTRO="$1"

if [ -z "$DISTRO" ]; then
  echo "Usage: ./install.sh [mac|debian|arch|fedora]"
  exit 1
fi

COMMON_PACKAGES=(
  tmux
  htop
  fzf
  bat
  eza
  ripgrep
  tldr
  jq
  ncdu
  asciinema
  neovim
  git
)

install_mac() {
  command -v brew >/dev/null 2>&1 || {
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  }

  brew update
  brew install "${COMMON_PACKAGES[@]}"
}

install_debian() {
  sudo apt update
  sudo apt install -y "${COMMON_PACKAGES[@]}"
}

install_arch() {
  sudo pacman -Syu --noconfirm "${COMMON_PACKAGES[@]}"
}

install_fedora() {
  sudo dnf install -y "${COMMON_PACKAGES[@]}"
}

case "$DISTRO" in
  mac)
    install_mac
    ;;
  debian|pop|ubuntu)
    install_debian
    ;;
  arch)
    install_arch
    ;;
  fedora)
    install_fedora
    ;;
  *)
    echo "not support $DISTRO"
    exit 1
    ;;
esac



echo "Finished !!!"