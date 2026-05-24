#!/bin/bash -e

OS_TYPE="$1"

if [ -z "$OS_TYPE" ]; then
    OS_TYPE=$(uname)
fi

FONTS_DIR="$HOME/dotfiles/fonts"

if [ ! -d "$FONTS_DIR" ]; then
    echo "No fonts directory found at $FONTS_DIR, skipping fonts installation."
    exit 0
fi

echo "Installing fonts..."

if [ "$OS_TYPE" == "Darwin" ]; then
    TARGET_DIR="$HOME/Library/Fonts"
    mkdir -p "$TARGET_DIR"
    cp "$FONTS_DIR"/* "$TARGET_DIR/"
    echo "Fonts installed for macOS."
elif [ "$OS_TYPE" == "Linux" ]; then
    TARGET_DIR="$HOME/.local/share/fonts"
    mkdir -p "$TARGET_DIR"
    cp "$FONTS_DIR"/* "$TARGET_DIR/"
    if command -v fc-cache >/dev/null 2>&1; then
        fc-cache -f -v > /dev/null
        echo "Fonts installed and cache updated for Linux."
    else
        echo "Fonts copied to $TARGET_DIR, but fc-cache not found. You may need to update the font cache manually."
    fi
else
    echo "Skipping fonts for unsupported OS: $OS_TYPE"
fi
