#!/bin/bash


plugins=(
    "https://github.com/romkatv/powerlevel10k"
    "https://github.com/zsh-users/zsh-autosuggestions"
    "https://github.com/zsh-users/zsh-completions"
    "https://github.com/zsh-users/zsh-syntax-highlighting"
    "https://github.com/jeffreytse/zsh-vi-mode.git"
    "https://github.com/lukechilds/zsh-nvm.git"
     ) 

mkdir -p ~/.config/zsh/plugins
mkdir -p ~/.config/tmux/plugins

for url in "${plugins[@]}"; do
    plug_dir=$(basename "$url" .git)
    if [ ! -d ~/.config/zsh/plugins/"$plug_dir" ]; then
        git clone "$url" ~/.config/zsh/plugins/"$plug_dir"
    else
        echo "Plugin $plug_dir already installed."
    fi
done

if [ ! -d ~/.config/tmux/plugins/tpm ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
else
    echo "TPM already installed."
fi