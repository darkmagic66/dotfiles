#!/usr/bin/env bash
# Add a new shared skill to the dotfiles.
# Usage:
#   ./add_skill.sh <skill-name>                    # creates with template frontmatter
#   ./add_skill.sh <skill-name> <source-file>      # copies content from source file
#   ./add_skill.sh <skill-name> -                  # reads SKILL.md from stdin
#
# To add a new agent: edit the AGENTS array below.
# Each entry: "<agent-name>:<subdir-inside-opencode-package>"
set -euo pipefail

NAME="${1:-}"
SOURCE="${2:-}"

if [ -z "$NAME" ]; then
  echo "usage: $0 <skill-name> [source-file | -]" >&2
  exit 1
fi

case "$NAME" in
  */*|*\\*|*..*) echo "invalid skill name: $NAME" >&2; exit 1 ;;
esac

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
SKILLS_DIR="$DOTFILES_DIR/skills"
PKG="$DOTFILES_DIR/opencode"
SKILL_DIR="$SKILLS_DIR/$NAME"
SKILL_FILE="$SKILL_DIR/SKILL.md"

info() { printf '\033[1;34m[add]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[ok]\033[0m  %s\n' "$*"; }
err()  { printf '\033[1;31m[err]\033[0m %s\n' "$*" >&2; }

if [ -e "$SKILL_DIR" ]; then
  err "skill '$NAME' already exists at $SKILL_DIR"
  exit 1
fi

AGENTS=(
  "opencode:.config/opencode/skills"
  "copilot:.copilot/skills"
  "claude:.claude/skills"
)

mkdir -p "$SKILL_DIR"

if [ -n "$SOURCE" ] && [ "$SOURCE" != "-" ] && [ -f "$SOURCE" ]; then
  cp "$SOURCE" "$SKILL_FILE"
  ok "copied SKILL.md from $SOURCE"
elif [ "${SOURCE:-}" = "-" ]; then
  cat > "$SKILL_FILE"
  ok "wrote SKILL.md from stdin"
else
  cat > "$SKILL_FILE" <<EOF
---
name: $NAME
description: TODO — one sentence covering what this skill does AND when to trigger it. Front-load the literal keywords users are likely to say.
---

# $NAME

TODO — describe what this skill does.
EOF
  ok "wrote SKILL.md from template (edit it to add the body)"
fi

for entry in "${AGENTS[@]}"; do
  agent="${entry%%:*}"
  prefix="${entry#*:}"
  link_dir="$PKG/$prefix/$NAME"
  mkdir -p "$link_dir"
  ln -srf "$SKILL_FILE" "$link_dir/SKILL.md"
  ok "linked $agent → skills/$NAME/SKILL.md"
done

info "restowing opencode package"
stow --dir="$DOTFILES_DIR" --target="$HOME" --restow opencode 2>&1 \
  | grep -vE "^BUG in find_stowed_path" || true

echo
ok "skill '$NAME' created at $SKILL_DIR"
echo "  source:  $SKILL_FILE"
echo "  visible in: ${AGENTS[*]%%:*}"
