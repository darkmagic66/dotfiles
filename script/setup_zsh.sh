#!/bin/bash

#plugins=(
#    "https://github.com/romkatv/powerlevel10k
#    https://github.com/zsh-users/zsh-autosuggestions
#    https://github.com/zsh-users/zsh-completions
#    https://github.com/zsh-users/zsh-syntax-highlighting"
#    ) 

#plugins=(
#    https://github.com/romkatv/powerlevel10k
#    https://github.com/zsh-users/zsh-autosuggestions
#    https://github.com/zsh-users/zsh-completions
#    https://github.com/zsh-users/zsh-syntax-highlighting
#    ) 

plugins=(
    "https://github.com/romkatv/powerlevel10k"
    "https://github.com/zsh-users/zsh-autosuggestions"
    "https://github.com/zsh-users/zsh-completions"
    "https://github.com/zsh-users/zsh-syntax-highlighting"
    "https://github.com/jeffreytse/zsh-vi-mode.git"
    "https://github.com/lukechilds/zsh-nvm.git"
     ) 

for url in "${plugins[@]}"; do
    plug_dir=$(basename "$url" .git)
    git clone "$url" ~/zsh/plugins/"$plug_dir"
done
