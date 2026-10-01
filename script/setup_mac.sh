#!/bin/bash
set -euo pipefail

echo "Applying macOS defaults..."

# Show hidden files in Finder
defaults write com.apple.finder AppleShowAllFiles -bool true

# Disable press-and-hold for keys (enables key repeat instead of accent picker)
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Disable text substitutions (they corrupt code and shell input)
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# F1–F12 act as function keys without holding Fn
defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true

# Fast keyboard repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable natural scrolling (uncomment if you prefer traditional scroll)
# defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# Show battery percentage in menu bar
defaults write ~/Library/Preferences/com.apple.menuextra.battery ShowPercent -string "YES"

# Always show scrollbars
defaults write NSGlobalDomain AppleShowScrollBars -string "Always"

# Finder: show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Finder: show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Save screenshots to ~/Pictures/Screenshots
mkdir -p ~/Pictures/Screenshots
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"

# Disable screenshot floating thumbnail
defaults write com.apple.screencapture show-thumbnail -bool false

# Use current directory as default search scope in Finder
#defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Avoid creating .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Enable tap-to-click on trackpad
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Three-finger drag (accessibility)
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true

# Reduce transparency (Accessibility → Display → Reduce transparency)
defaults write com.apple.universalaccess reduceTransparency -bool true

# Trackpad tracking speed (System Settings slider: 0.0 slow → 3.0 fastest).
# 2.4 = 80% of maximum. Logout/login once if a fresh install ignores it.
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 2.4
defaults -currentHost write NSGlobalDomain com.apple.trackpad.scaling -float 2.4

# Trackpad scroll speed: maximum (Accessibility → Pointer Control → Trackpad
# Options slider). Logout/login once if a fresh install ignores the value.
defaults write NSGlobalDomain com.apple.scrollwheel.scaling -float 7
defaults -currentHost write NSGlobalDomain com.apple.scrollwheel.scaling -float 7

# Dock icon size, pixels (default 48; 36 and below shrink dock a lot)
defaults write com.apple.dock tilesize -int 36
# Dock magnification (cursor-hover zoom) — off; static icons only
defaults write com.apple.dock magnification -bool false

# Display scaling ("More Space") can NOT be set with `defaults` on Apple
# Silicon. Either pick it manually once (System Settings → Displays), or:
#   brew install displayplacer
#   displayplacer list        # find your display id
#   displayplacer "id:<ID> res:<W>x<H> scaling:on"
# then paste the working line here (uncommented) for future installs.

killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

echo "macOS defaults applied. Some changes require logout/restart to take effect."
