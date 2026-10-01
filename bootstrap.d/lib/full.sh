#!/usr/bin/env bash
# bootstrap.d/lib/full.sh — full install flow, ported verbatim from the former
# install.sh body (architecture-v2 spec G4). Caller sets UPDATE (false|true):
#   bootstrap        → UPDATE=false (full path)
#   bootstrap --update → UPDATE=true (skips packages/git/stow/mac-defaults/fonts;
#                        setup_zsh + setup_skills run with --update)
set -euo pipefail

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

# 2. OS/DISTRO detection already performed by bootstrap/lib/common.sh (same
#    normalization as the old install.sh block); report it the same way.
if [ "$OS_TYPE" == "Darwin" ]; then
  echo "Detected OS: macOS"
elif [ "$OS_TYPE" == "Linux" ]; then
  echo "Detected OS: Linux ($DISTRO)"
fi

echo "==================================="
echo "       $OS_TYPE $DISTRO            "
echo "==================================="

export DOTFILES_DIR DISTRO OS_TYPE

# Make top-level setup scripts executable at once (adapters are sourced)
chmod +x "$DOTFILES_DIR"/script/*.sh

# 3. Install Basic Packages (manifest → distro adapter via setup_basic.sh)
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

# 4. GNU Stow (same block as `bootstrap config`)
if ! $UPDATE; then
  # shellcheck source=bootstrap.d/lib/config.sh
  . "$DOTFILES_DIR/bootstrap.d/lib/config.sh"
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
