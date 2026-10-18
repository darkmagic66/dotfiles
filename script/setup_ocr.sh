#!/usr/bin/env bash
# setup_ocr.sh - install Open Code Review (ocr) CLI + portable agent skill.
#
# OpenCodeReview (https://github.com/alibaba/open-code-review) is Alibaba's
# AI-powered code-review CLI. It is published to npm as
# @alibaba-group/open-code-review and installs the `ocr` command; reviews are
# run against git diffs with a configured LLM. This script installs the CLI
# with mise's node and drops the portable agent skill (skills/open-code-review
# plus the delegate variant) into each agent's user-scope skill directory so
# agents can drive `ocr` themselves.
#
# Usage:
#   bash setup_ocr.sh            # install CLI + skill (idempotent)
#
# Requires: mise in PATH (arch: pacman, mac: brew, other: the mise installer).
# Configure an LLM before the first review (interactive, not automated here):
#   ocr config provider && ocr config model && ocr llm test

set -euo pipefail

# mise installs node's global npm bin under its own tree; the dotfiles zsh puts
# mise's shims on PATH, but bootstrap may run from a plain shell.
export PATH="$HOME/.local/bin:$PATH"

OCR_RAW_BASE="https://raw.githubusercontent.com/alibaba/open-code-review/main/skills"
OCR_SKILLS=(open-code-review open-code-review-delegate)

AGENT_SKILL_DIRS=(
  "$HOME/.config/opencode/skills"
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.agents/skills"
)

# --- ocr CLI (npm: @alibaba-group/open-code-review) -------------------------
install_ocr() {
  if command -v ocr >/dev/null 2>&1 || mise exec -- ocr --version >/dev/null 2>&1; then
    echo "ocr already installed."
    return
  fi
  echo "Installing Open Code Review (ocr)..."
  # node comes from mise.toml (installed by setup_programing.sh).
  mise exec -- npm install -g @alibaba-group/open-code-review
}

# --- portable agent skill (SKILL.md, no node deps) --------------------------
install_skills() {
  local agent_dir skill url dest
  for agent_dir in "${AGENT_SKILL_DIRS[@]}"; do
    for skill in "${OCR_SKILLS[@]}"; do
      dest="$agent_dir/$skill"
      mkdir -p "$dest"
      url="$OCR_RAW_BASE/$skill/SKILL.md"
      if curl -fsSL "$url" -o "$dest/SKILL.md"; then
        echo "  skill installed -> $dest/SKILL.md"
      else
        echo "warning: could not fetch $url; continuing"
        rmdir "$dest" 2>/dev/null || true
      fi
    done
  done
}

install_ocr
install_skills

echo "Open Code Review setup complete."
echo "Configure an LLM before first review:  ocr config provider && ocr config model"
