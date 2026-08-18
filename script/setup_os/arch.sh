#!/bin/bash
# setup_os/arch.sh — extras for the Arch Linux family.
# Applies to: arch cachyos archlabs endeavouros manjaro
# Sourced by setup_basic.sh. Self-guard: no-op when sourced for other distros.

case "${DISTRO:-}" in
  arch|cachyos|archlabs|endeavouros|manjaro) ;;
  *)
    [[ "${BASH_SOURCE[0]:-${0}}" == "${0}" ]] && exit 0 || return 0 ;;
esac

# Packages that used to be AUR-only but are now in the official extra repo.
# Plain pacman, no AUR helper needed.
ARCH_PACKAGES=(
  waybar
  yazi
  awww          # swww successor (codeberg.org/LGFae/awww)
  brightnessctl
  wl-clipboard
  powerline-fonts
  ncdu
  playerctl
  udisks2
  blueman
  zed
)

echo "Installing Arch extra packages (official repo)..."
sudo pacman -S --needed --noconfirm "${ARCH_PACKAGES[@]}"

# --- AUR helper ------------------------------------------------------------
# VS Code (visual-studio-code-bin, MS binary) is the only package that needs
# an AUR helper. CachyOS ships paru in the [cachyos] repo; plain Arch doesn't.
if ! command -v yay >/dev/null 2>&1 && ! command -v paru >/dev/null 2>&1; then
  if sudo pacman -S --needed --noconfirm paru 2>/dev/null; then
    echo "paru installed from [cachyos] repo."
  else
    echo "Building yay from AUR..."
    sudo pacman -S --needed --noconfirm base-devel git
    tmpdir="$(mktemp -d)"
    trap 'rm -rf "$tmpdir"' EXIT
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    ( cd "$tmpdir/yay" && makepkg -si --noconfirm )
  fi
fi

# --- VS Code (MS binary, AUR) ----------------------------------------------
echo "Installing Visual Studio Code..."
if command -v paru >/dev/null 2>&1; then
  paru -S --needed --noconfirm visual-studio-code-bin
elif command -v yay >/dev/null 2>&1; then
  yay -S --needed --noconfirm visual-studio-code-bin
else
  echo "Warning: no AUR helper (yay/paru) found. Install manually: yay -S visual-studio-code-bin"
fi

# --- Enable system services for Hyprland session (best-effort) -------------
echo "Enabling system services..."
sudo systemctl enable --now \
  NetworkManager bluetooth cups fstrim.timer udisks2 2>/dev/null || true
if systemctl list-unit-files snapper-timeline.timer >/dev/null 2>&1; then
  sudo systemctl enable --now \
    snapper-timeline.timer snapper-cleanup.timer 2>/dev/null || true
fi

# --- CachyOS mirror rater -------------------------------------------------
if command -v cachyos-rate-mirrors >/dev/null 2>&1; then
  sudo cachyos-rate-mirrors 2>/dev/null || true
fi

# --- Optional Hyprland GUI extras (NOT installed by default) --------------
# Uncomment the line below to install when you want them:
#   paru -S --needed waypaper nwg-look nwg-displays gtk4-layer-shell
#
# tree-sitter-cli is also available via pacman from extra:
#   sudo pacman -S --needed 
