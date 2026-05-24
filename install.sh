#!/bin/bash -e

DOTFILES_DIR="$HOME/dotfiles"

echo "==================================="
echo "   Dotfiles Installation Script    "
echo "==================================="

# 1. Check Internet Connection
echo "Checking internet connection..."
if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    echo "Internet connection: OK"
else
    echo "Error: No internet connection."
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

# 3. Install Basic Packages
echo "Installing base packages..."
chmod +x "$DOTFILES_DIR/script/setup_basic.sh"
"$DOTFILES_DIR/script/setup_basic.sh" "$DISTRO"

# 4. GNU Stow
echo "Stowing dotfiles..."
cd "$DOTFILES_DIR"
if ! command -v stow >/dev/null 2>&1; then
    echo "Error: GNU Stow is not installed. Please install it first."
    exit 1
fi
stow alacritty ideavim nvim tmux zsh

# 5. OS-Specific Setup
if [ "$DISTRO" == "mac" ]; then
    echo "Running macOS specific setup..."
    chmod +x "$DOTFILES_DIR/script/setup_mac.sh"
    "$DOTFILES_DIR/script/setup_mac.sh"
fi

# 6. Post-install Scripts
echo "Running post-install scripts..."

chmod +x "$DOTFILES_DIR/script/setup_fonts.sh"
"$DOTFILES_DIR/script/setup_fonts.sh" "$OS_TYPE"

chmod +x "$DOTFILES_DIR/script/setup_zsh.sh"
"$DOTFILES_DIR/script/setup_zsh.sh"

chmod +x "$DOTFILES_DIR/script/setup_programing.sh"
"$DOTFILES_DIR/script/setup_programing.sh"

chmod +x "$DOTFILES_DIR/script/setup_ai.sh"
"$DOTFILES_DIR/script/setup_ai.sh"

echo "==================================="
echo "   Installation Complete!          "
echo "==================================="
