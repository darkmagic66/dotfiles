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

# Group windows by application in Mission Control. Required with AeroSpace:
# it parks windows bottom-right and Mission Control shrinks them unreadably
# small without grouping. See "A note on mission control" in AeroSpace guide.
dflt com.apple.dock expose-group-apps -bool true

# Reduce animations (near-instant UI; all reversible via `defaults delete`).
# Smooth scrolling deliberately untouched (NSScrollAnimationEnabled stays on).
dflt NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
dflt NSGlobalDomain NSWindowResizeTime -float 0.001
dflt NSGlobalDomain QLPanelAnimationDuration -float 0
dflt NSGlobalDomain NSScrollViewRubberbanding -bool false
dflt NSGlobalDomain NSDocumentRevisionsWindowTransformAnimation -bool false
dflt NSGlobalDomain NSToolbarFullScreenAnimationDuration -float 0
dflt NSGlobalDomain NSBrowserColumnAnimationSpeedMultiplier -float 0
dflt com.apple.dock autohide-time-modifier -float 0
dflt com.apple.dock autohide-delay -float 0
dflt com.apple.dock expose-animation-duration -float 0.1
dflt com.apple.dock springboard-show-duration -float 0
dflt com.apple.dock springboard-hide-duration -float 0
dflt com.apple.dock springboard-page-duration -float 0
dflt com.apple.finder DisableAllAnimations -bool true
dflt com.apple.Mail DisableSendAnimations -bool true
dflt com.apple.Mail DisableReplyAnimations -bool true

# Login profile picture from repo wallpaper (takes effect after logout)
REPO_ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd -P)"
if [ -f "$REPO_ROOT/wallpaper/profile-nagato.jpg" ]; then
  sudo dscl . -create "/Users/$USER" Picture "$REPO_ROOT/wallpaper/profile-nagato.jpg" \
    || echo "warning: dscl login picture failed"
fi

# Desktop wallpaper after login (System Events asks for Automation permission
# once — allow it; applies to every desktop/space)
if [ -f "$REPO_ROOT/wallpaper/background-nagato.jpg" ]; then
  osascript -e "tell application \"System Events\" to set picture of every desktop to \"$REPO_ROOT/wallpaper/background-nagato.jpg\"" \
    || echo "warning: desktop wallpaper failed"
fi

# Login window wallpaper (best-effort: replaces the cached admin image the
# loginwindow draws behind the prompt; needs sudo; verify visually at logout)
if [ -f "$REPO_ROOT/wallpaper/lock-nagato-01.jpg" ]; then
  sips -s format png "$REPO_ROOT/wallpaper/lock-nagato-01.jpg" --out /tmp/login-nagato.png >/dev/null 2>&1 \
    && sudo cp /tmp/login-nagato.png /Library/Caches/com.apple.desktop.admin.png \
    || echo "warning: login wallpaper failed"
  rm -f /tmp/login-nagato.png
fi

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
