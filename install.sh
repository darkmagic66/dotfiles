#!/bin/bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

echo "==================================="
echo "   Dotfiles Installation Script    "
echo "==================================="

# 1. Check Internet Connection
echo "Checking internet connection..."
if curl -sSf https://github.com -o /dev/null 2>&1; then
  echo "Internet connection: OK"
else
  echo "Error: No internet connection (could not reach github.com)."
  exit 1
fi

# 2. Detect OS / Distro
OS_TYPE=$(uname)
DISTRO=""

if [ "$OS_TYPE" == "Darwin" ]; then
  DISTRO="mac"
  echo "Detected OS: macOS"
elif [ "$OS_TYPE" == "Linux" ]; then
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
  elif [ -f /etc/debian_version ]; then
    DISTRO="debian"
  else
    DISTRO="linux_unknown"
  fi
  echo "Detected OS: Linux ($DISTRO)"
else
  echo "Unsupported OS: $OS_TYPE"
  exit 1
fi

# Make all scripts executable at once
chmod +x "$DOTFILES_DIR"/script/*.sh

# 3. Install Basic Packages
echo "Installing base packages..."
"$DOTFILES_DIR/script/setup_basic.sh" "$DISTRO"

# 4. GNU Stow
echo "Stowing dotfiles..."
cd "$DOTFILES_DIR"
if ! command -v stow >/dev/null 2>&1; then
  echo "Error: GNU Stow is not installed. Please install it first."
  exit 1
fi
stow alacritty hypr hyprshell ideavim kitty nvim opencode tmux waybar zsh

# 5. OS-Specific Setup
if [ "$DISTRO" == "mac" ]; then
  echo "Running macOS specific setup..."
  "$DOTFILES_DIR/script/setup_mac.sh"
fi

# 6. Post-install Scripts
echo "Running post-install scripts..."

"$DOTFILES_DIR/script/setup_fonts.sh" "$OS_TYPE"
"$DOTFILES_DIR/script/setup_zsh.sh"
"$DOTFILES_DIR/script/setup_programing.sh"
"$DOTFILES_DIR/script/setup_skills.sh"

if [ "$DISTRO" == "cachyos" ] || [ "$DISTRO" == "arch" ]; then
  echo "Running hyprshell setup (Hyprland window switcher)..."
  "$DOTFILES_DIR/script/setup_hyprshell.sh"
fi

echo "==================================="
echo "   Installation Complete!          "
echo "==================================="
echo
echo "Next steps:"
echo "  1. Restart your shell or run: exec \$SHELL"
echo "  2. Open tmux and press prefix + I to install tmux plugins"
echo "  3. Open nvim and run :Mason to install LSP servers"
echo "  4. Restart opencode/claude/codex to pick up new skills"