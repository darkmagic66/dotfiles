#!/bin/bash
set -euo pipefail

OS_TYPE="${1:-$(uname)}"

FONTS_DIR="$HOME/dotfiles/fonts"

if [ ! -d "$FONTS_DIR" ]; then
  echo "No fonts directory found at $FONTS_DIR, skipping fonts installation."
  exit 0
fi

is_windows() {
  [[ "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == cygwin* || "${OS:-}" == "Windows_NT" ]]
}

link_font() {
  local src="$1" dest="$2"
  if is_windows; then
    cmd //c mklink //H "$dest" "$src" >/dev/null 2>&1 || cp "$src" "$dest"
  else
    ln -sfn "$src" "$dest"
  fi
}

echo "Installing fonts (via symlinks)..."

if [ "$OS_TYPE" == "Darwin" ]; then
  TARGET_DIR="$HOME/Library/Fonts"
  mkdir -p "$TARGET_DIR"
  for font in "$FONTS_DIR"/*; do
    [ -f "$font" ] || continue
    link_font "$font" "$TARGET_DIR/$(basename "$font")"
  done
  echo "Fonts symlinked for macOS."

elif [ "$OS_TYPE" == "Linux" ]; then
  TARGET_DIR="$HOME/.local/share/fonts"
  mkdir -p "$TARGET_DIR"
  for font in "$FONTS_DIR"/*; do
    [ -f "$font" ] || continue
    link_font "$font" "$TARGET_DIR/$(basename "$font")"
  done
  if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f > /dev/null
    echo "Fonts symlinked and cache updated for Linux."
  else
    echo "Fonts symlinked to $TARGET_DIR, but fc-cache not found. Update font cache manually."
  fi

elif is_windows; then
  # Windows fonts must be in the Windows font directory for most apps to see them
  TARGET_DIR="$(cmd //c echo %LOCALAPPDATA%\\Microsoft\\Windows\\Fonts 2>/dev/null | tr -d '\r')"
  if [ -n "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
    for font in "$FONTS_DIR"/*; do
      [ -f "$font" ] || continue
      cp "$font" "$TARGET_DIR/$(basename "$font")"
    done
    echo "Fonts copied for Windows (symlinks not reliable for Windows font dir)."
  else
    echo "Could not determine Windows font directory. Install fonts manually."
  fi

else
  echo "Skipping fonts for unsupported OS: $OS_TYPE"
fi