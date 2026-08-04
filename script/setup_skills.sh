#!/usr/bin/env bash
# setup_skills.sh - install agent skills via symlinks from ~/dotfiles/skills/ to each agent's discovery dir.
#
# Usage:
#   bash setup_skills.sh            # init submodules + create symlinks (idempotent)
#   bash setup_skills.sh --update   # pull latest in submodules first, then re-symlink
#
# Cross-OS: works on Linux, macOS, and Windows (Git Bash / WSL / Developer Mode required for symlinks).

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
SKILLS_DIR="$DOTFILES_DIR/skills"

# --- Skill selection --------------------------------------------------------
# Each entry: "<relative path under skills/>" — the folder containing SKILL.md.
# Use "all" for a source to install every skill/<name>/ under that submodule.

SUPERPOWERS_SKILLS=(all)                 # obra/superpowers — take all ~14 skills

MATTP0COCK_SKILLS=(
  productivity/grill-me
  productivity/handoff
  productivity/teach
  productivity/writing-great-skills
  engineering/tdd
  engineering/code-review
  engineering/codebase-design
  engineering/diagnosing-bugs
  engineering/research
  engineering/implement
  engineering/to-spec
  engineering/to-tickets
  engineering/setup-matt-pocock-skills
)

CavEMAN_SKILLS=(all)                     # juliusbrussee/caveman — take all (caveman, cavecrew, caveman-commit, etc.)

SKILL_TISSUE_SKILLS=(backseat cvmn)      # skill-tissue/skills — pick backseat + cvmn (skip artai)

# Plain folders (always installed, no submodule)
CUSTOM_SKILLS=(karpathy-guidelines)

# --- Agent skill discovery dirs --------------------------------------------
# Edit this list to add/remove agents. Each agent will get symlinks to every skill.
AGENT_SKILL_DIRS=(
  "$HOME/.config/opencode/skills"
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.agents/skills"
)

# --- OS detection -----------------------------------------------------------
is_windows() {
  [[ "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == cygwin* || "${OS:-}" == "Windows_NT" ]]
}

link_skill() {
  local src="$1" dest="$2"
  if is_windows; then
    # Windows: use mklink /D for directory junction (needs Developer Mode or admin)
    cmd //c rmdir "$dest" 2>/dev/null || true
    cmd //c mklink //J "$dest" "$src" >/dev/null
  else
    ln -sfn "$src" "$dest"
  fi
}

# --- Update submodules if requested ----------------------------------------
if [[ "${1:-}" == "--update" ]]; then
  echo "Updating skill submodules to latest upstream..."
  rtk git -C "$DOTFILES_DIR" submodule update --remote --merge
  echo "Submodules updated. Remember to commit + push the new pinned commits."
  echo
fi

# --- Init submodules (idempotent) ------------------------------------------
echo "Initializing skill submodules..."
rtk git -C "$DOTFILES_DIR" submodule update --init --recursive

# --- Collect skill paths to install ----------------------------------------
declare -a SKILL_PATHS=()

expand_source() {
  local submodule_dir="$1"
  local skill_list=("${@:2}")
  local base="$SKILLS_DIR/$submodule_dir"
  if [[ ! -d "$base" ]]; then
    echo "  warning: $base not found, skipping"
    return
  fi
  for entry in "${skill_list[@]}"; do
    if [[ "$entry" == "all" ]]; then
      # Find every folder containing a SKILL.md under skills/<submodule>/skills/*/
      local found_dir
      for found_dir in "$base"/skills/*/; do
        [[ -d "$found_dir" ]] || continue
        # Skip if it's a nested category folder (matt has engineering/, productivity/, etc.)
        # Heuristic: nested category = no SKILL.md directly inside, but has subfolders with SKILL.md
        if [[ -f "$found_dir/SKILL.md" ]]; then
          SKILL_PATHS+=("$found_dir")
        else
          # Nested category — recurse one level
          local nested
          for nested in "$found_dir"*/; do
            [[ -d "$nested" && -f "$nested/SKILL.md" ]] && SKILL_PATHS+=("$nested")
          done
        fi
      done
    else
      # Specific path like "productivity/grill-me"
      local target="$base/skills/$entry"
      if [[ -d "$target" && -f "$target/SKILL.md" ]]; then
        SKILL_PATHS+=("$target/")
      else
        echo "  warning: $target not found or missing SKILL.md, skipping"
      fi
    fi
  done
}

echo "Collecting skills..."
expand_source "superpowers"        "${SUPERPOWERS_SKILLS[@]}"
expand_source "mattpocock-skills" "${MATTP0COCK_SKILLS[@]}"
expand_source "caveman"           "${CavEMAN_SKILLS[@]}"
expand_source "skill-tissue-skills" "${SKILL_TISSUE_SKILLS[@]}"

# Custom (plain folder) skills
for name in "${CUSTOM_SKILLS[@]}"; do
  local_dir="$SKILLS_DIR/$name"
  if [[ -d "$local_dir" && -f "$local_dir/SKILL.md" ]]; then
    SKILL_PATHS+=("$local_dir/")
  else
    echo "  warning: $local_dir not found or missing SKILL.md, skipping"
  fi
done

echo "Found ${#SKILL_PATHS[@]} skills to install."

# --- Create symlinks for each agent ----------------------------------------
for agent_dir in "${AGENT_SKILL_DIRS[@]}"; do
  echo "Installing to: $agent_dir"
  mkdir -p "$agent_dir"
  for skill_path in "${SKILL_PATHS[@]}"; do
    skill_name="$(basename "$skill_path")"
    dest="$agent_dir/$skill_name"
    link_skill "$skill_path" "$dest"
  done
done

echo
echo "Done. Installed ${#SKILL_PATHS[@]} skills to ${#AGENT_SKILL_DIRS[@]} agent dirs."
echo
echo "To update skills later:   bash $DOTFILES_DIR/script/setup_skills.sh --update"
echo "To add a new skill:       see $SKILLS_DIR/README.md"