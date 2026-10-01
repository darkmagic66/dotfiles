#!/bin/bash
set -euo pipefail

echo "Applying macOS defaults..."

# Warn-and-continue wrapper: one unwritable domain (locked plist, fresh
# machine, cfprefsd hiccup) must not abort the entire stage under set -e.
# Inserts the `write` verb (call sites pass domain + key + value only).
dflt() {
  if [ "${1:-}" = "-currentHost" ]; then
    local flag="$1"; shift
    defaults "$flag" write "$@" || echo "warning: defaults write failed: $flag $*"
  else
    defaults write "$@" || echo "warning: defaults write failed: $*"
  fi
}

# Show hidden files in Finder
dflt com.apple.finder AppleShowAllFiles -bool true

# Disable press-and-hold for keys (enables key repeat instead of accent picker)
dflt NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Disable text substitutions (they corrupt code and shell input)
dflt NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
dflt NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
dflt NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
dflt NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
dflt NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# F1–F12 act as function keys without holding Fn
dflt NSGlobalDomain com.apple.keyboard.fnState -bool true

# Fast keyboard repeat rate
dflt NSGlobalDomain KeyRepeat -int 2
dflt NSGlobalDomain InitialKeyRepeat -int 15

# Disable natural scrolling (uncomment if you prefer traditional scroll)
# defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# Show battery percentage in menu bar
dflt ~/Library/Preferences/com.apple.menuextra.battery ShowPercent -string "YES"

# Always show scrollbars
dflt NSGlobalDomain AppleShowScrollBars -string "Always"

# Finder: show path bar
dflt com.apple.finder ShowPathbar -bool true

# Finder: show status bar
dflt com.apple.finder ShowStatusBar -bool true

# Save screenshots to ~/Pictures/Screenshots
mkdir -p ~/Pictures/Screenshots
dflt com.apple.screencapture location -string "$HOME/Pictures/Screenshots"

# Disable screenshot floating thumbnail
dflt com.apple.screencapture show-thumbnail -bool false

# Use current directory as default search scope in Finder
#defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Avoid creating .DS_Store files on network volumes
dflt com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Enable tap-to-click on trackpad
dflt com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
dflt -currentHost NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Three-finger drag (accessibility)
dflt com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true

# Reduce transparency (Accessibility → Display → Reduce transparency)
dflt com.apple.universalaccess reduceTransparency -bool true

# Trackpad tracking speed (System Settings slider: 0.0 slow → 3.0 fastest).
# 2.4 = 80% of maximum. Logout/login once if a fresh install ignores it.
dflt NSGlobalDomain com.apple.trackpad.scaling -float 2.4
dflt -currentHost NSGlobalDomain com.apple.trackpad.scaling -float 2.4

# Trackpad scroll speed: maximum (Accessibility → Pointer Control → Trackpad
# Options slider). Logout/login once if a fresh install ignores the value.
dflt NSGlobalDomain com.apple.scrollwheel.scaling -float 7
dflt -currentHost NSGlobalDomain com.apple.scrollwheel.scaling -float 7

# Dock icon size, pixels (default 48; 36 and below shrink dock a lot)
dflt com.apple.dock tilesize -int 36
# Dock magnification (cursor-hover zoom) — off; static icons only
dflt com.apple.dock magnification -bool false

# Night Shift (always on): intentionally NOT scripted. Apple exposes no
# `defaults` key for it — the CoreBrightness daemon ignores direct plist
# writes, so a script can only drive it via a third-party CLI. Manual steps
# (once, persists across installs):
#   System Settings → Displays → Night Shift → Schedule: Custom,
#   From 12:00 AM To 11:59 PM (≈ always on), plus color-temperature slider.

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
