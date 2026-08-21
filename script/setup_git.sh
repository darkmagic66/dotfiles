#!/bin/bash
set -euo pipefail

set_if_empty() {
  local key="$1" prompt="$2"
  local current
  current="$(git config --global --get "$key" 2>/dev/null || true)"
  if [ -n "$current" ]; then
    echo "git $key already set: $current"
    return
  fi
  printf '%s: ' "$prompt"
  read -r value
  if [ -n "$value" ]; then
    git config --global "$key" "$value"
  else
    echo "Skipping $key (empty input)."
  fi
}

set_if_empty user.name "Your git user.name"
set_if_empty user.email "Your git user.email"

echo "Git identity configured."
