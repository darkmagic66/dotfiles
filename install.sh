#!/bin/bash
set -euo pipefail

UPDATE=false
[[ "${1:-}" == "--update" ]] && UPDATE=true

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

# 2. Detect OS / Distro (export so child scripts read via ${VAR:-fallback})
OS_TYPE="$(uname)"
DISTRO=""

if [ "$OS_TYPE" == "Darwin" ]; then
  DISTRO="mac"
  echo "Detected OS: macOS"
elif [ "$OS_TYPE" == "Linux" ]; then
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO="$ID"
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

echo "==================================="
echo "       $OS_TYPE $DISTRO            "
echo "==================================="


export DOTFILES_DIR DISTRO OS_TYPE

# Make top-level setup scripts executable at once (setup_os/ files are sourced)
chmod +x "$DOTFILES_DIR"/script/*.sh

# 3. Install Basic Packages + distro-specific extras (sourced from setup_os/)
echo "==================================="
echo "   Installing base packages...     "
echo "==================================="
if ! $UPDATE; then
  "$DOTFILES_DIR/script/setup_basic.sh"
fi

# 3.5 Git identity (interactive; skipped in --update)
if ! $UPDATE; then
  "$DOTFILES_DIR/script/setup_git.sh"
fi

# 4. GNU Stow
if ! $UPDATE; then
  echo "Stowing dotfiles..."
  command -v stow >/dev/null 2>&1 || {
    echo "Error: GNU Stow is not installed. Please install it first."
    exit 1
  }

  # Resolve machine role (personal/company) via bootstrap/lib/hosts.sh;
  # unknown host without a tty dies there with a clear message (never guess).
  if [ -f "$DOTFILES_DIR/bootstrap/lib/hosts.sh" ]; then
    # shellcheck disable=SC1091
    . "$DOTFILES_DIR/bootstrap/lib/hosts.sh"
    resolve_role
    echo "Resolved role: $ROLE (host: $(hostname))"
  else
    echo "Error: $DOTFILES_DIR/bootstrap/lib/hosts.sh not found; cannot resolve machine role."
    exit 1
  fi

  (
    cd "$DOTFILES_DIR"
    echo "==================================="
    echo "      Running Stow Process         "
    echo "==================================="
    # Common packages: stowed on every platform
    stow -t "$HOME" zsh tmux nvim kitty alacritty ideavim opencode xxh
    # Linux/Wayland-only packages; mac skips them
    if [ "$DISTRO" != "mac" ]; then
      stow -t "$HOME" -d linux hypr waybar gtk qt fontconfig
    fi
    # Role packages (personal/company), only when the package holds real
    # content — stowing a gitkeep-only dir would plant a .gitkeep link in $HOME
    if [ -n "$ROLE" ] && [ -d "roles/$ROLE" ] && [ -n "$(find "roles/$ROLE" -mindepth 1 ! -name '.gitkeep' -print -quit)" ]; then
      stow -t "$HOME" -d roles "$ROLE"
    fi
    # mac-specific packages: none yet — add `stow -d mac <pkg>` here
  )
fi

if ! $UPDATE && [ "$DISTRO" == "mac" ]; then
  echo "Running macOS specific setup..."
  "$DOTFILES_DIR/script/setup_mac.sh"
fi

# 6. Post-install Scripts
echo "==================================="
echo "   Running post-install scripts   "
echo "==================================="


if ! $UPDATE; then
  "$DOTFILES_DIR/script/setup_fonts.sh"
fi
if $UPDATE; then
  "$DOTFILES_DIR/script/setup_zsh.sh" --update
else
  "$DOTFILES_DIR/script/setup_zsh.sh"
fi
"$DOTFILES_DIR/script/setup_programing.sh"
if $UPDATE; then
  "$DOTFILES_DIR/script/setup_skills.sh" --update
else
  "$DOTFILES_DIR/script/setup_skills.sh"
fi
"$DOTFILES_DIR/script/setup_rtk.sh"

echo "==================================="
echo "   Installation Complete!          "
echo "==================================="
echo
echo "Next steps:"
echo "  1. Restart your shell or run: exec \$SHELL"
echo "  2. Open tmux and press prefix + I to install tmux plugins"
echo "  3. Open nvim and run :Mason to install LSP servers"
echo "  4. Restart opencode/claude/codex to pick up new skills"
