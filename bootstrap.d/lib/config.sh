#!/usr/bin/env bash
# bootstrap.d/lib/config.sh — stow stage, ported verbatim from the former
# install.sh stow block (GNU Stow presence check, role resolution, package
# groups with portable content guard). Expects DOTFILES_DIR/DISTRO/OS_TYPE
# set (sourced via bootstrap entry or full.sh); honors PKG_DRY_RUN=1 by
# passing stow -n.
echo "Stowing dotfiles..."
command -v stow >/dev/null 2>&1 || {
  echo "Error: GNU Stow is not installed. Please install it first."
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
  stow -t "$HOME" ${STOW_DRY[@]+"${STOW_DRY[@]}"} zsh tmux nvim kitty alacritty ideavim opencode xxh
  # Linux/Wayland-only packages; mac skips them
  if [ "$DISTRO" != "mac" ]; then
    stow -t "$HOME" ${STOW_DRY[@]+"${STOW_DRY[@]}"} -d linux hypr waybar gtk qt fontconfig
  fi
  # Role packages (personal/company), only when the package holds real
  # content — stowing a gitkeep-only dir would plant a .gitkeep link in $HOME
  if [[ -n "${ROLE:-}" ]] && [ -d "roles/$ROLE" ] && [ -n "$(find "roles/$ROLE" -mindepth 1 ! -type d ! -name '.gitkeep' -print 2>/dev/null | head -n 1)" ]; then
    stow -t "$HOME" ${STOW_DRY[@]+"${STOW_DRY[@]}"} -d roles "$ROLE"
  fi
  # mac-specific packages: none yet — add `stow -d mac <pkg>` here
)
