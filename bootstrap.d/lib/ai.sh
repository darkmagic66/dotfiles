# ai.sh — bootstrap ai subcommands (spec G5): list/update/status over git submodules.
# Personal skills (skills/personal/) don't exist yet; external skills = the 4 submodules.

_ai_usage() {
  echo "Usage: bootstrap ai [list|update|status]" >&2
}

ai_list() {
  echo "Personal:"
  echo "  (none yet)"
  echo "External:"
  git submodule status | while IFS= read -r line; do
    char="${line:0:1}"
    rest="${line:1}"
    sha="${rest%% *}"
    name="${rest#* }"
    name="${name%% (*}"
    printf '  [%s] %-22s (pinned %s)\n' "$char" "$name" "${sha:0:8}"
  done
}

ai_update() {
  # setup_skills.sh's "submodule update --init" resets worktrees to pinned
  # commits, so re-link FIRST, then pull latest (pins staged+committed by user).
  echo "Re-linking skills to agents (setup_skills.sh)..."
  "$DOTFILES_DIR/script/setup_skills.sh"
  echo "Updating skill submodules (git submodule update --remote --merge)..."
  git submodule update --remote --merge
  echo "Done. New pins are uncommitted until you git add skills/* and commit."
}

ai_status() {
  git submodule status
}

ai_main() {
  case "${1:-}" in
    list)   ai_list ;;
    update) ai_update ;;
    status) ai_status ;;
    *)
      _ai_usage
      exit 1
      ;;
  esac
}
