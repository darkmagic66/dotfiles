#!/bin/bash
# setup_os/mac.sh — extras for macOS.
# Applies to: mac
# Sourced by setup_basic.sh. Self-guard: no-op when sourced for other distros.

case "${DISTRO:-}" in
  mac) ;;
  *)
    [[ "${BASH_SOURCE[0]:-${0}}" == "${0}" ]] && exit 0 || return 0 ;;
esac

# Brewfile carries casks/brews incl. zed, visual-studio-code, firefox,
# alacritty, kitty, aldente, gnupg. fnm is intentionally not in Brewfile —
# it's installed by setup_programing.sh.
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
BREWFILE="$DOTFILES_DIR/Brewfile"
if [ -f "$BREWFILE" ]; then
  echo "Running brew bundle..."
  brew bundle --file="$BREWFILE"
else
  echo "No Brewfile found at $BREWFILE, skipping brew bundle."
fi