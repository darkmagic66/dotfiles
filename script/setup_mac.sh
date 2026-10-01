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

# Display scaling "More Space": no `defaults` key on Apple Silicon.
# Set MAC_DISPLAY_ID + MAC_MORE_SPACE_RES (from `displayplacer list`), e.g.
#   MAC_DISPLAY_ID="<id>" MAC_MORE_SPACE_RES="1800x1169" ./script/setup_mac.sh
# Unset → silently skipped (comment stays as the recipe).
if [ -n "${MAC_DISPLAY_ID:-}" ] && [ -n "${MAC_MORE_SPACE_RES:-}" ]; then
  if command -v displayplacer >/dev/null 2>&1; then
    displayplacer "id:${MAC_DISPLAY_ID} res:${MAC_MORE_SPACE_RES} scaling:on" \
      || echo "warning: displayplacer scaling failed"
  else
    echo "warning: displayplacer not installed; skipping More Space"
  fi
fi

# Automatically adjust brightness: ON. Lives in the root-owned CoreBrightness
# plist (per-display key), so this needs sudo; without it, toggle manually
# in System Settings → Displays.
if sudo -n true 2>/dev/null || { [ -t 0 ] && sudo -v; }; then
  _cb_plist="/private/var/root/Library/Preferences/com.apple.CoreBrightness.plist"
  _disp_id="$(sudo /usr/libexec/PlistBuddy -c "Print :DisplayPreferences:" "$_cb_plist" 2>/dev/null | grep "= Dict" | grep -v AutoBrightnessCurve | awk '{print $1}' | head -n 1)"
  if [ -n "${_disp_id:-}" ]; then
    sudo /usr/libexec/PlistBuddy -c "Add :DisplayPreferences:$_disp_id:AutoBrightnessEnable bool true" "$_cb_plist" >/dev/null 2>&1 || true
    sudo /usr/libexec/PlistBuddy -c "Set :DisplayPreferences:$_disp_id:AutoBrightnessEnable true" "$_cb_plist" \
      || echo "warning: auto-brightness enable failed"
    sudo killall cfprefsd corebrightnessd 2>/dev/null || true
  else
    echo "warning: auto-brightness skipped (no display id found)"
  fi
  unset _cb_plist _disp_id
else
  echo "warning: auto-brightness skipped (needs sudo; toggle in System Settings → Displays)"
fi

killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

echo "macOS defaults applied. Some changes require logout/restart to take effect."
