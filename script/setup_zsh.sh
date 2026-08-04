#!/bin/bash
set -euo pipefail

# zsh plugins cloned into ~/.config/zsh/plugins/ (sourced by .zshrc)
# NOTE: zsh-nvm removed — replaced by fnm (installed via setup_basic.sh)
PLUGINS=(
  "https://github.com/romkatv/powerlevel10k"
  "https://github.com/zsh-users/zsh-autosuggestions"
  "https://github.com/zsh-users/zsh-completions"
  "https://github.com/zsh-users/zsh-syntax-highlighting"
  "https://github.com/jeffreytse/zsh-vi-mode.git"
)

ZSH_PLUGINS_DIR="$HOME/.config/zsh/plugins"
TMUX_PLUGINS_DIR="$HOME/.config/tmux/plugins"

mkdir -p "$ZSH_PLUGINS_DIR" "$TMUX_PLUGINS_DIR"

UPDATE=false
[[ "${1:-}" == "--update" ]] && UPDATE=true

for url in "${PLUGINS[@]}"; do
  plug_dir=$(basename "$url" .git)
  target="$ZSH_PLUGINS_DIR/$plug_dir"
  if [ ! -d "$target" ]; then
    git clone "$url" "$target"
  elif $UPDATE; then
    echo "Updating $plug_dir..."
    git -C "$target" pull --ff-only
  else
    echo "Plugin $plug_dir already installed."
  fi
done

# tmux plugin manager
if [ ! -d "$TMUX_PLUGINS_DIR/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm "$TMUX_PLUGINS_DIR/tpm"
elif $UPDATE; then
  echo "Updating tpm..."
  git -C "$TMUX_PLUGINS_DIR/tpm" pull --ff-only
else
  echo "TPM already installed."
fi

# Set zsh as default shell if not already
CURRENT_SHELL=$(basename "$SHELL")
if [ "$CURRENT_SHELL" != "zsh" ]; then
  ZSH_PATH=$(command -v zsh 2>/dev/null || true)
  if [ -n "$ZSH_PATH" ]; then
    echo "Changing default shell to zsh..."
    chsh -s "$ZSH_PATH" || echo "Warning: chsh failed. Run manually: chsh -s $ZSH_PATH"
  else
    echo "Warning: zsh not found in PATH. Install it first, then run: chsh -s \$(which zsh)"
  fi
else
  echo "zsh is already the default shell."
fi