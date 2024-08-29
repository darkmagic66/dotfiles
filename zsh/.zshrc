# Enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# ===========================================  Path ==============================================
export JAVA_PATH="/usr/lib/jvm"
export JAVA_HOME="$JAVA_PATH/java-1.17.0-openjdk-amd64"
export JAVA_11="$JAVA_PATH/java-11-openjdk-amd64"
export JAVA_17="$JAVA_PATH/java-17-openjdk-amd64"
# export PATH="$JAVA_11/bin:$PATH"
export PATH="$JAVA_17/bin:$PATH"

export CMAKE_PATH="$HOME/Downloads/cmake-3.29.2-linux-x86_64"
export PATH="$CMAKE_PATH/bin:$PATH"

export GOPATH="$HOME/go"
export GOBIN="$GOPATH"/bin/
export PATH=$GOBIN:$PATH
export PATH=$PATH:/usr/local/go/bin

export SCRIPT_PATH=$HOME/dotfiles/bin/
export PATH=$SCRIPT_PATH:$PATH

export ZSH="$HOME/.oh-my-zsh"

export XDG_CONFIG_HOME=$HOME/.config
export TMUX_PLUGIN_MANAGER_PATH=$XDG_CONFIG_HOME/tmux/plugins

export EDITOR="$HOME/.config/nvim"

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
 
# ================================================================================================

# ===========================================  zsh config ==============================================

ZSH_THEME="powerlevel10k/powerlevel10k" 

# ===========================================  Plugins ==============================================
plugins=(
   git
   zsh-autosuggestions
   zsh-syntax-highlighting
   zsh-completions
)
source $ZSH/oh-my-zsh.sh
# ===================================================================================================
# User configuration
bindkey '^ ' autosuggest-accept
# ===========================================  alias ==============================================
# alias nvim=vim
alias vim=nvim
alias vimdiff="nvim -d"
alias ls=exa
alias "ls -ltr"="exa -l --sort=modified"
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
# =================================================================================================
# Load Angular CLI autocompletion.
source <(ng completion script)
# source ~/powerlevel10k/powerlevel10k.zsh-theme


# bun completions
[ -s "/home/pongsatorn66/.bun/_bun" ] && source "/home/pongsatorn66/.bun/_bun"
