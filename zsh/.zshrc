# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# To customize prompt, run `p10k configure` or edit ~/dotfiles/zsh/.p10k.zsh.
[[ ! -f ~/dotfiles/zsh/.p10k.zsh ]] || source ~/dotfiles/zsh/.p10k.zsh

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$XDG_CONFIG_HOME/.local/share"
export XDG_CACHE_HOME="$XDG_CONFIG_HOME/.cache"

export TMUX_PLUGIN_MANAGER_PATH=$XDG_CONFIG_HOME/tmux/plugins
export PATH="$HOME/local/nvim-linux64/bin:$PATH"

 export TERMINAL=alacritty

# java
export JAVA_PATH="/usr/lib/jvm"
export JAVA_HOME="$JAVA_PATH/java-1.17.0-openjdk-amd64"
export JAVA_11="$JAVA_PATH/java-11-openjdk-amd64"
export JAVA_17="$JAVA_PATH/java-17-openjdk-amd64"
# export PATH="$JAVA_11/bin:$PATH"
export PATH="$JAVA_17/bin:$PATH"

# go
export GOPATH="$HOME/go"
export GOBIN="$GOPATH"/bin/
export PATH=$GOBIN:$PATH
export PATH=$PATH:/usr/local/go/bin

# alias
alias vim=nvim
alias vimdiff="nvim -d"
alias ls=exa
alias "ls -ltr"="exa -l --sort=modified"

#zsh
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

source $HOME/zsh/plugins/powerlevel10k/powerlevel10k.zsh-theme
source $HOME/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $HOME/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source $HOME/zsh/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh
source $HOME/zsh/plugins/zsh-nvm/zsh-nvm.plugin.zsh
fpath=($HOME/zsh/plugins/zsh-completions/src $fpath)
autoload -U compinit; compinit


# load file
#if command -v ng &> /dev/null; then
 # source <(ng completion script)
#fi


# bun completions
[ -s "/home/pongsatorn66/.bun/_bun" ] && source "/home/pongsatorn66/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

#export NVM_DIR="$HOME/.nvm"
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
#[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
