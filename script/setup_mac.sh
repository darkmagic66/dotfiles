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

# Caps Lock → Control (native hidutil: immediate + login LaunchAgent so it
# survives reboots; no Karabiner needed for this one).
_caps_map='{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0}]}'
hidutil property --set "$_caps_map" >/dev/null 2>&1 \
  || echo "warning: hidutil caps remap failed"
_caps_plist="$HOME/Library/LaunchAgents/com.dotfiles.caps2ctrl.plist"
mkdir -p "$HOME/Library/LaunchAgents"
if [ ! -f "$_caps_plist" ]; then
  cat > "$_caps_plist" <<'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.dotfiles.caps2ctrl</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/hidutil</string>
    <string>property</string>
    <string>--set</string>
    <string>{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0}]}</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
PLIST_EOF
  launchctl load "$_caps_plist" 2>/dev/null || true
fi
unset _caps_map _caps_plist

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

# Double-click speed: slowest (most forgiving interval, ~1.7s).
# Value read live from the M5 where double-click works; higher = slower.
# Logout/login once if a fresh install ignores it.
dflt NSGlobalDomain com.apple.mouse.doubleClickThreshold -float 1.7

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

# Display scaling "More Space": no `defaults` key on Apple Silicon and no
# third-party tools wanted — set manually (once, persists):
#   System Settings → Displays → Display → More Space.
# Automatically adjust brightness: ON — set manually (once, persists):
#   System Settings → Displays → Automatically adjust brightness.

killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

echo "macOS defaults applied. Some changes require logout/restart to take effect."
