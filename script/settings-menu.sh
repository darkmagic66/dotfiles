#!/usr/bin/env bash
# settings-menu.sh — unified settings launcher (fuzzel dmenu)
# Bound to Super+, in hyprland.lua.
# Opens a fuzzel menu listing lightweight settings GUIs, runs the selected one.
set -u

choice=$(printf 'Display\nAudio\nNetwork\nBluetooth\nAppearance\nWallpaper' \
  | fuzzel --dmenu --prompt 'Settings: ' 2>/dev/null) || exit 0

case "$choice" in
  Display)    exec nwg-displays ;;
  Audio)      exec pavucontrol ;;
  Network)    exec nm-connection-editor ;;
  Bluetooth)  exec blueman-manager ;;
  Appearance) exec nwg-look ;;
  Wallpaper)  exec waypaper ;;
  *)          exit 1 ;;
esac