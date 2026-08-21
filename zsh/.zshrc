# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Powerlevel10k config
[[ ! -f ~/dotfiles/zsh/.p10k.zsh ]] || source ~/dotfiles/zsh/.p10k.zsh

# --- XDG dirs ---------------------------------------------------------------
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export TMUX_PLUGIN_MANAGER_PATH=$XDG_CONFIG_HOME/tmux/plugins

# --- PATH (idempotent, no duplicates) ---------------------------------------
# Note: ~/go/bin and /usr/local/go/bin are added automatically by mise when go
# is active, so they don't need to be listed here.
typeset -U path
path=(
  $HOME/.local/bin
  $path
)

# --- mise (manages go, java, node, rust via mise.toml) ----------------------
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# --- bun --------------------------------------------------------------------
export BUN_INSTALL="$HOME/.bun"
[[ -s "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"
path=($BUN_INSTALL/bin $path)

# --- Aliases ----------------------------------------------------------------
alias vim=nvim
alias vimdiff="nvim -d"
alias ls="eza"
alias ll="eza -l --git --group-directories-first"
alias la="eza -la --git --group-directories-first"
alias lt="eza --tree --level=2"
alias lr="eza -l --sort=modified"

# --- zsh options ------------------------------------------------------------
ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=5000
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt incappendhistory
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# --- Plugins ----------------------------------------------------------------
# fpath MUST come before compinit so zsh-completions are picked up.
fpath=($XDG_CONFIG_HOME/zsh/plugins/zsh-completions/src $fpath)

source $XDG_CONFIG_HOME/zsh/plugins/powerlevel10k/powerlevel10k.zsh-theme
source $XDG_CONFIG_HOME/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $XDG_CONFIG_HOME/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source $XDG_CONFIG_HOME/zsh/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh

autoload -U compinit && compinit

# --- Machine-specific overrides (not tracked in dotfiles) -------------------
[[ -r $XDG_CONFIG_HOME/zsh/.zshrc.local ]] && source $XDG_CONFIG_HOME/zsh/.zshrc.local

