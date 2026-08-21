#!/usr/bin/env bash
# setup_rtk.sh - activate rtk for opencode (installs the opencode plugin).
#
# Usage:
#   bash setup_rtk.sh            # install plugin if missing (idempotent)
#
# Requires: rtk binary in PATH (installed by setup_programing.sh).
# Creates:  ~/.config/opencode/plugins/rtk.ts

set -euo pipefail

if ! command -v rtk >/dev/null 2>&1; then
  echo "rtk not found in PATH — skipping opencode plugin activation."
  echo "Install rtk first via setup_programing.sh."
  exit 0
fi

echo "Activating rtk for opencode..."
# --no-patch: skip Claude Code settings.json patching (opencode plugin only)
# rtk init is idempotent — skips if the plugin is already up to date
rtk init -g --opencode --no-patch

echo "rtk opencode plugin ready."
