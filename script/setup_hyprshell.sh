#!/bin/bash
set -euo pipefail

HYPRSHELL_VERSION="${HYPRSHELL_VERSION:-4.10.8}"
HYPRSHELL_BIN="$HOME/.local/bin/hyprshell"
HYPRSHELL_DATA_DIR="$HOME/.local/share/hyprshell"
HYPRSHELL_RELEASES_URL="https://github.com/H3rmt/hyprshell/releases"

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  ASSET_ARCH="x86_64" ;;
  aarch64) ASSET_ARCH="aarch64" ;;
  *) echo "Unsupported arch: $ARCH"; exit 1 ;;
esac

if command -v pacman >/dev/null 2>&1; then
  if ! pacman -Q gtk4-layer-shell >/dev/null 2>&1; then
    echo "Installing gtk4-layer-shell (required by hyprshell)..."
    sudo pacman -S --needed --noconfirm gtk4-layer-shell
  fi
fi

if [ -x "$HYPRSHELL_BIN" ]; then
  INSTALLED="$("$HYPRSHELL_BIN" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
  if [ "$INSTALLED" = "$HYPRSHELL_VERSION" ]; then
    echo "hyprshell $HYPRSHELL_VERSION already installed at $HYPRSHELL_BIN"
  else
    echo "hyprshell $INSTALLED found, upgrading to $HYPRSHELL_VERSION..."
  fi
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
TARBALL="$TMPDIR/hyprshell.tar.zst"
URL="$HYPRSHELL_RELEASES_URL/download/v$HYPRSHELL_VERSION/hyprshell-$HYPRSHELL_VERSION-$ASSET_ARCH.tar.zst"

echo "Downloading hyprshell $HYPRSHELL_VERSION ($ASSET_ARCH)..."
if ! curl -fSL -o "$TARBALL" "$URL"; then
  echo "Error: failed to download $URL"
  echo "Check \$HYPRSHELL_VERSION (current: $HYPRSHELL_VERSION) or set it to a valid release tag."
  exit 1
fi

echo "Extracting..."
tar --zstd -xf "$TARBALL" -C "$TMPDIR"

mkdir -p "$(dirname "$HYPRSHELL_BIN")"
install -m 0755 "$TMPDIR/hyprshell" "$HYPRSHELL_BIN"

mkdir -p "$HYPRSHELL_DATA_DIR"
if [ -f "$TMPDIR/usr-share.tar" ]; then
  tar -xf "$TMPDIR/usr-share.tar" -C "$HYPRSHELL_DATA_DIR"
fi

echo "hyprshell $HYPRSHELL_VERSION installed to $HYPRSHELL_BIN"
echo "Themes extracted to $HYPRSHELL_DATA_DIR/themes"
echo
echo "To symlink system-wide themes (so the settings editor finds them):"
echo "  sudo mkdir -p /usr/share/hyprshell && sudo cp -r $HYPRSHELL_DATA_DIR/themes /usr/share/hyprshell/"
echo
echo "Generate or edit config via:"
echo "  $HYPRSHELL_BIN config generate   # opens GUI editor"
echo "  $HYPRSHELL_BIN config edit       # edits existing config"
echo
echo "Verify with: $HYPRSHELL_BIN --version"