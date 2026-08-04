#!/usr/bin/env bash
set -euo pipefail

SKILL="$HOME/dotfiles/skills/karpathy-guidelines/SKILL.md"
URL="https://raw.githubusercontent.com/multica-ai/andrej-karpathy-skills/main/skills/karpathy-guidelines/SKILL.md"

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

curl -fsSL "$URL" -o "$tmp"

if diff -q "$SKILL" "$tmp" >/dev/null; then
  echo "karpathy-guidelines: already up to date"
  exit 0
fi

echo "karpathy-guidelines: changes detected"
diff "$SKILL" "$tmp" || true

mv "$tmp" "$SKILL"
trap - EXIT
echo "Updated. Review and commit."
