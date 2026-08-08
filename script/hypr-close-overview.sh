#!/bin/bash
# Close hyprshell Overview when Super is released (Hyprland-side workaround).
#
# hyprshell's Overview mode doesn't expose a CloseOverview socat command
# (see crates/core-lib/src/transfer/structs.rs: ExternalTransferType has
# OpenOverview but no CloseOverview). Overview only closes via Esc, click,
# or selecting a window. This script injects an Escape keypress via wtype
# *only* when the hyprshell_overview layer surface is currently present,
# so Super+1, Super+M etc. don't get spurious Esc sent to focused apps.
#
# Wired into hyprland.lua as a release bind on Super_L.
set -euo pipefail

if ! command -v wtype >/dev/null 2>&1; then
  exit 0
fi

# `hyprctl layers` lists namespaces of currently mapped layer surfaces.
# If hyprshell_overview is in that list, the Overview GUI is open.
if hyprctl layers 2>/dev/null | grep -q "namespace: hyprshell_overview"; then
  wtype -k Escape
fi