#!/bin/bash -e

DISTRO="$1"

if [ -z "$DISTRO" ]; then
  echo "Usage: ./setup_basic.sh [mac|debian|arch|cachyos|fedora]"
  exit 1
fi

COMMON_PACKAGES=(
  tmux
  htop
  fzf
  bat
  eza
  ripgrep
  jq
  ncdu
  neovim
  git
  stow
)

ARCH_PACKAGES=(
  fd
  zsh
  kitty
  ttf-jetbrains-mono-nerd
  noto-fonts-thai
)

AUR_PACKAGES=(
  fnm
)

install_arch() {
  sudo pacman -Syu --noconfirm "${COMMON_PACKAGES[@]}" "${ARCH_PACKAGES[@]}"
  # AUR packages (fnm is in Chaotic-AUR on CachyOS or plain AUR elsewhere)
  if ! pacman -Q fnm >/dev/null 2>&1; then
    if command -v paru >/dev/null 2>&1; then
      paru -S --needed --noconfirm "${AUR_PACKAGES[@]}"
    elif command -v yay >/dev/null 2>&1; then
      yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"
    else
      echo "Warning: AUR helper (paru/yay) not found. Install manually: ${AUR_PACKAGES[*]}"
    fi
  fi
}

  brew update
  brew install "${COMMON_PACKAGES[@]}" tldr asciinema fnm

  if [ -f "$HOME/dotfiles/Brewfile" ]; then
    echo "Running brew bundle..."
    brew bundle --file="$HOME/dotfiles/Brewfile"
  fi
}

install_debian() {
  sudo apt update
  sudo apt install -y "${COMMON_PACKAGES[@]}" tldr asciinema python3 build-essential
}

install_arch() {
  sudo pacman -Syu --noconfirm "${COMMON_PACKAGES[@]}" "${ARCH_PACKAGES[@]}"
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

echo "Base packages installed successfully."
