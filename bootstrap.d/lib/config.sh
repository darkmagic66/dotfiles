#!/usr/bin/env bash
# bootstrap.d/lib/config.sh — stow stage, ported verbatim from the former
# install.sh stow block (GNU Stow presence check, role resolution, package
# groups with portable content guard). Expects DOTFILES_DIR/DISTRO/OS_TYPE
# set (sourced via bootstrap entry or full.sh); honors PKG_DRY_RUN=1 by
# passing stow -n.
echo "Stowing dotfiles..."
# Stow is a hard requirement of this stage. If the packages stage died before
# installing it (e.g. one bad formula aborted the whole brew line), install
# it here on demand instead of aborting the entire stow run.
if ! command -v stow >/dev/null 2>&1; then
  echo "GNU Stow not found — installing it now..."
  case "${DISTRO:-}" in
    mac)
      command -v brew >/dev/null 2>&1 \
        || { echo "Error: brew not found either; run './bootstrap packages' first."; exit 1; }
      brew install stow
      ;;
    arch|cachyos|archlabs|endeavouros|manjaro)
      sudo pacman -S --needed --noconfirm stow
      ;;
    debian|pop|ubuntu)
      sudo apt update && sudo apt install -y stow
      ;;
    fedora)
      sudo dnf install -y stow
      ;;
    *)
      echo "Error: GNU Stow is not installed and DISTRO='${DISTRO:-unknown}' has no known installer."
      exit 1
      ;;
  esac
fi
command -v stow >/dev/null 2>&1 || {
  echo "Error: GNU Stow install failed. Install it manually, then re-run."
  exit 1
}

# Resolve machine role (personal/company) via bootstrap.d/lib/hosts.sh;
# unknown host without a tty dies there with a clear message (never guess).
if [ -f "$DOTFILES_DIR/bootstrap.d/lib/hosts.sh" ]; then
  # shellcheck disable=SC1091
  . "$DOTFILES_DIR/bootstrap.d/lib/hosts.sh"
  resolve_role
  echo "Resolved role: $ROLE (host: $(hostname))"
else
  echo "Error: $DOTFILES_DIR/bootstrap.d/lib/hosts.sh not found; cannot resolve machine role."
  exit 1
fi

(
  STOW_DRY=()
  if [ "${PKG_DRY_RUN:-0}" = "1" ]; then
    STOW_DRY=(-n)
  fi
  cd "$DOTFILES_DIR"
  echo "==================================="
  echo "      Running Stow Process         "
  echo "==================================="
  # Common packages: stowed on every platform
  stow -t "$HOME" ${STOW_DRY[@]+"${STOW_DRY[@]}"} zsh tmux nvim kitty alacritty ideavim opencode xxh git
  # Linux/Wayland-only packages; mac skips them
  if [ "$DISTRO" != "mac" ]; then
    stow -t "$HOME" ${STOW_DRY[@]+"${STOW_DRY[@]}"} -d linux hypr waybar gtk qt fontconfig
  fi
  # Role packages (personal/company), only when the package holds real
  # content — stowing a gitkeep-only dir would plant a .gitkeep link in $HOME
  if [[ -n "${ROLE:-}" ]] && [ -d "roles/$ROLE" ] && [ -n "$(find "roles/$ROLE" -mindepth 1 ! -type d ! -name '.gitkeep' -print 2>/dev/null | head -n 1)" ]; then
    stow -t "$HOME" ${STOW_DRY[@]+"${STOW_DRY[@]}"} -d roles "$ROLE"
  fi
  # mac-specific packages (AeroSpace, Karabiner: mac-only; linux skips this —
  # mirror image of the linux gate above)
  if [ "$DISTRO" == "mac" ]; then
    stow -t "$HOME" ${STOW_DRY[@]+"${STOW_DRY[@]}"} -d mac aerospace karabiner neru
  fi
)
