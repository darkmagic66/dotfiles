#!/bin/bash
set -euo pipefail

DISTRO="$1"

if [ -z "$DISTRO" ]; then
  echo "Usage: ./setup_basic.sh [mac|debian|arch|cachyos|fedora]"
  exit 1
fi

# Packages available on all OSes via their native package managers
COMMON_PACKAGES=(
  tmux
  htop
  fzf
  bat
  ripgrep
  jq
  ncdu
  neovim
  git
  stow
  zsh
  zip
  unzip
  curl
  wget
  git-delta
  zoxide
  starship
)

# Packages only in arch repos (not apt/brew)
ARCH_PACKAGES=(
  fd
  eza
  kitty
  ttf-jetbrains-mono-nerd
  noto-fonts
  powerline-fonts
  gtk4-layer-shell
  # Wayland / Hyprland audio + input stack
  wl-clipboard
  pipewire
  pipewire-pulse
  pipewire-alsa
  wireplumber
  brightnessctl
  playerctl
  hyprpaper
  hypridle
  hyprlock
  swww
  network-manager-applet
)

# AUR packages (installed via paru/yay, or pre-installed via Chaotic-AUR on CachyOS)
AUR_PACKAGES=(
  fnm
)

install_mac() {
  command -v brew >/dev/null 2>&1 || {
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  }

  brew update
  brew install "${COMMON_PACKAGES[@]}" eza fd tldr asciinema fnm

  if [ -f "$HOME/dotfiles/Brewfile" ]; then
    echo "Running brew bundle..."
    brew bundle --file="$HOME/dotfiles/Brewfile"
  fi
}

install_debian() {
  sudo apt update
  # eza is not in Ubuntu 22.04/Pop!_OS 22.04 repos — install from official deb repo
  if ! command -v eza >/dev/null 2>&1; then
    echo "Installing eza from upstream deb repo..."
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  fi
  sudo apt install -y "${COMMON_PACKAGES[@]}" eza fd-find tldr asciinema python3 build-essential
  # fd is named fd-find on debian — create symlink
  [ -f /usr/bin/fdfind ] && [ ! -f /usr/local/bin/fd ] && sudo ln -s /usr/bin/fdfind /usr/local/bin/fd
}

install_arch() {
  sudo pacman -Syu --noconfirm "${COMMON_PACKAGES[@]}" "${ARCH_PACKAGES[@]}"
  # Install paru AUR helper if neither paru nor yay is present.
  # CachyOS ships paru in the [cachyos] repo, so pacman will find it there first.
  if ! command -v paru >/dev/null 2>&1 && ! command -v yay >/dev/null 2>&1; then
    if sudo pacman -S --needed --noconfirm paru 2>/dev/null; then
      echo "paru installed from distro repo."
    else
      echo "Building paru from AUR..."
      sudo pacman -S --needed --noconfirm base-devel git
      tmpdir=$(mktemp -d)
      git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"
      (cd "$tmpdir/paru" && makepkg -si --noconfirm)
      rm -rf "$tmpdir"
    fi
  fi
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

  # Enable services for Hyprland session (no-op if already running)
  echo "Enabling system services..."
  sudo systemctl enable --now NetworkManager bluetooth cups fstrim.timer 2>/dev/null || true
  if systemctl list-unit-files snapper-timeline.timer >/dev/null 2>&1; then
    sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer 2>/dev/null || true
  fi
  if command -v cachyos-rate-mirrors >/dev/null 2>&1; then
    sudo cachyos-rate-mirrors 2>/dev/null || true
  fi
}

install_fedora() {
  sudo dnf install -y "${COMMON_PACKAGES[@]}" eza fd tldr asciinema
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