!#/bin/bash

# make finder find hidden file
defaults write -g AppleShowAllFiles -bool true
# make able to repeat key
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
