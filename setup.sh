#!/bin/bash

# uname: unix name
OS_TYPE=$(uname)
COMMAND=""


internet_on() {
    # ping -c 1 google.com
    ping -c 1 8.8.8.8 > /dev/null 2>&1
    return $?
}

if internet_on; then 
    echo "Connect the Internet"
else 
    echo "No Internet Connection"
fi 

# stow */

# tmux plugin
# git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm


# space is importrant
if [ "$OS_TYPE" == "Darwin" ]; then 
    echo "Running on MacOs"
    # COMMAN="brew install"
    brew bundle
elif [ "$OS_TYPE" == "Linux" ]; then
    echo "Running on Linux"
    # COMMAN="sudo apt install"
else 
    echo "Unssupoort"
    exit 1 
fi
