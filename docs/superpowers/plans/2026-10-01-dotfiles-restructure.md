# Dotfiles Restructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split platform-specific configs into `linux/` + `mac/`, make mac single-source via Brewfile, clean root into `docs/`, sync all docs.

**Architecture:** Common stow packages stay at repo root; platform dirs become separate stow target dirs (`stow -d linux|mac`). Moves are `git mv` to preserve history. Spec: `docs/superpowers/specs/2026-10-01-dotfiles-restructure-design.md`.

**Tech Stack:** bash + GNU Stow + Homebrew Brewfile. No test framework — verification via `stow -n` dry runs, grep checks, shellcheck.

## Global Constraints

- All moves use `git mv` (never plain mv) so `git status` shows renames
- CachyOS end-state must be identical: same packages, same symlinks, new paths only
- macOS must have ZERO Linux-only stow links and no duplicated brew installs
- `stow --restow` semantics for re-runs; never delete arbitrary $HOME content
- Work dir: `$HOME/dotfiles` (this repo). Current machine is CachyOS (arch family, `DISTRO=cachyos`)

---

### Task 1: Platform moves — linux/, docs/, mac/ placeholder

**Files:**
- Create: `linux/`, `mac/.gitkeep`, `docs/` (exists — spec already committed there)
- Move: `hypr/ waybar/ gtk/ qt/ fontconfig/ wallpaper/` → `linux/`
- Move: `plan.md install.flow.mmd ZSH.md HYPRSUNSET-MIRROR-CTM.md` → `docs/`
- Modify: `linux/hypr/.config/hypr/modules/autostart.lua:20` (wallpaper path)

**Interfaces:**
- Produces: `linux/` containing hypr waybar gtk qt fontconfig wallpaper; `docs/` containing 4 former root files; path `linux/wallpaper/background-nagato.jpg`

- [ ] **Step 1: Move linux-only dirs**

```bash
git mv hypr waybar gtk qt fontconfig wallpaper linux/
```

- [ ] **Step 2: Move root doc files**

```bash
git mv plan.md install.flow.mmd ZSH.md HYPRSUNSET-MIRROR-CTM.md docs/
```

- [ ] **Step 3: Create mac placeholder**

```bash
mkdir -p mac && touch mac/.gitkeep
```

- [ ] **Step 4: Fix wallpaper path references (move breaks them)**

In `linux/hypr/.config/hypr/modules/autostart.lua` line 20, replace:

```lua
    hl.exec_cmd("awww img $HOME/dotfiles/wallpaper/background-nagato.jpg")
```

with:

```lua
    hl.exec_cmd("awww img $HOME/dotfiles/linux/wallpaper/background-nagato.jpg")
```

In `linux/hypr/.config/hypr/note.md`, update the `hyprpaper:` wallpaper line the same way (add `linux/` into the path). Then sweep for stragglers:

```bash
rg -n 'dotfiles/wallpaper' --glob '!.git' --glob '!docs' .
```

Expected: no matches (all refs now say `dotfiles/linux/wallpaper`).

- [ ] **Step 5: Verify renames**

```bash
git status --short | head -40
```

Expected: only `R` (rename) lines, `A mac/.gitkeep`, `M` only on `autostart.lua` and `note.md` — plus `?? docs/superpowers/` from the spec commit is fine (it IS committed; should not appear).

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "refactor: move linux-only configs into linux/, root docs into docs/, add mac/ placeholder"
```

---

### Task 2: .stow-local-ignore — protect new dirs

**Files:**
- Modify: `.stow-local-ignore`

**Interfaces:**
- Consumes: `linux/`, `mac/`, `docs/` from Task 1
- Produces: bare `stow .` from repo root will never symlink `linux/`, `mac/`, `docs/`; `dog` already ignored (stays)

- [ ] **Step 1: Edit `.stow-local-ignore`** — end result:

```
.git
fonts
script
ai-env
dog
skills
Brewfile
README.md
ZSH.md
HYPRSUNSET-MIRROR-CTM.md
^/README.*
^/LICENSE.*
^/COPYING
.stow-local-ignore
install.sh
install.flow.mmd
mise.toml
linux
mac
docs
plan.md
```

Notes: add `skills` (currently missing — bare `stow .` would symlink the whole skills tree into $HOME), add `linux`, `mac`, `docs`. Keep legacy entries (`ZSH.md` etc.) — harmless, files moved but ignore rules are cheap and cover old checkouts.

- [ ] **Step 2: Verify with dry run**

```bash
cd ~/dotfiles && stow -n . 2>&1 | rtk head -10
```

Expected: dry run proposes links for stow packages only — NO `linux/`, `mac/`, `docs/`, `skills/`, `script/`, `fonts/` paths in output. (This is a sanity check; install.sh never runs bare `stow .`, but the ignore list must protect against it.)

- [ ] **Step 3: Commit**

```bash
git add .stow-local-ignore && git commit -m "chore: ignore linux/mac/docs/skills in stow-local-ignore"
```

---

### Task 3: install.sh — distro-aware stow

**Files:**
- Modify: `install.sh:67-81` (the GNU Stow block)

**Interfaces:**
- Consumes: `$DISTRO` exported by install.sh itself (values: `mac`, arch-family IDs like `cachyos`, `debian`, fedora); `linux/`, `mac/` dirs from Task 1
- Produces: on non-mac, stows common + linux packages; on mac, stows common only

- [ ] **Step 1: Replace the stow block (lines from `if ! $UPDATE` through the closing `fi` after the subshell).** New content:

```bash
if ! $UPDATE; then
  echo "Stowing dotfiles..."
  command -v stow >/dev/null 2>&1 || {
    echo "Error: GNU Stow is not installed. Please install it first."
    exit 1
  }
  (
    cd "$DOTFILES_DIR"
    echo "==================================="
    echo "      Running Stow Process         "
    echo "==================================="
    # Common packages: stowed on every platform
    stow zsh tmux nvim kitty alacritty ideavim opencode xxh
    # Linux/Wayland-only packages; mac skips them
    if [ "$DISTRO" != "mac" ]; then
      stow -d linux hypr waybar gtk qt fontconfig
    fi
    # mac-specific packages: none yet — add `stow -d mac <pkg>` here
  )
fi
```

Key deltas vs old: `gtk hypr qt waybar fontconfig` removed from the unconditioned list; common list now excludes all linux-only dirs; `-d linux` prefixes platform packages.

- [ ] **Step 2: Shellcheck**

```bash
command -v shellcheck >/dev/null 2>&1 || sudo pacman -S --noconfirm shellcheck
shellcheck install.sh
```

Expected: no errors. (Any pre-existing warnings in untouched code are out of scope — note and leave.)

- [ ] **Step 3: Dry-run the linux path locally**

```bash
cd ~/dotfiles && stow -n zsh tmux nvim kitty alacritty ideavim opencode xxh && stow -n -d linux hypr waybar gtk qt fontconfig
```

Expected: exit 0, no "CONFLICT" output (existing links are already stowed from these packages — if a CONFLICT appears, resolve with `stow --restow` at apply time, not by deleting).

- [ ] **Step 4: Commit**

```bash
git add install.sh && git commit -m "feat: distro-aware stow — common packages everywhere, linux-only behind DISTRO guard"
```

---

### Task 4: Package dedupe — Brewfile single source on mac

**Files:**
- Modify: `Brewfile`
- Modify: `script/setup_basic.sh:46-53` (`install_mac` body)

**Interfaces:**
- Consumes: `setup_os/mac.sh` (already runs `brew bundle` — unchanged)
- Produces: mac install path = brew bootstrap (if missing) + `brew update` + brew bundle; every COMMON package present in Brewfile exactly once

- [ ] **Step 1: Append COMMON-only packages to `Brewfile`** (keep existing lines; final file):

```
# bin — COMMON_PACKAGES additions (single mac source; setup_basic.sh mac branch no longer brew-installs)
brew 'htop'
brew 'fd'
brew 'fzf'
brew 'bat'
brew 'ripgrep'
brew 'zoxide'
brew 'git-delta'
brew 'lazygit'
brew 'tree-sitter-cli'
brew 'tldr'
brew 'asciinema'
brew 'zip'
brew 'unzip'
brew 'wget'
```

(already present and NOT re-added: tmux htop… check list: tmux, jq, git, zsh, stow, eza, mise, nvim — all already in Brewfile; do not duplicate them)

- [ ] **Step 2: Trim `install_mac` in `script/setup_basic.sh`** — replace lines 46-53:

```bash
install_mac() {
  command -v brew >/dev/null 2>&1 || {
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  }
  brew update
}
```

Rationale comment above the function must change to: `# Packages installed via Brewfile (see setup_os/mac.sh) — single source of truth on mac.`

- [ ] **Step 3: Shellcheck + grep dedupe assertion**

```bash
shellcheck script/setup_basic.sh
# every brew name in COMMON_PACKAGES must appear in Brewfile (or be handled by setup_os/mac.sh)
for p in tmux htop fd fzf zoxide bat ripgrep jq neovim git stow zsh zip unzip curl wget git-delta eza kitty lazygit tree-sitter-cli mise; do
  rg -q "(brew|cask) '$p'" Brewfile || echo "MISSING from Brewfile: $p"
done
```

Expected: shellcheck clean; `MISSING` prints nothing (kitty is a `cask 'kitty'` in Brewfile — cask pattern covers it; wget added in Step 1). Address any other MISSING line before commit.

- [ ] **Step 4: Commit**

```bash
git add Brewfile script/setup_basic.sh && git commit -m "refactor: Brewfile as single source of truth for mac packages"
```

---

### Task 5: Docs sync

**Files:**
- Modify: `README.md` (Layout tree + "What gets installed" stow line + Install notes)
- Modify: `script/README.md:15` (stow list), `:71-74` (mac.sh — drop fnm comment line), `:73-74` region (setup_mac.sh description unchanged), `:105` region (no change needed if accurate)
- Modify: `docs/install.flow.mmd` (moved in Task 1 — now lives at docs/)

**Interfaces:**
- Consumes: final layout from Tasks 1-4

- [ ] **Step 1: README.md edits.** Layout tree replaced with:

```
~/dotfiles/
├── install.sh            # entry point
├── Brewfile               # macOS homebrew bundle (single source for mac packages)
├── mise.toml              # toolchain versions for setup_programing.sh
├── script/                # setup_basic.sh, setup_os/<distro>.sh, setup_zsh.sh, …
├── linux/                 # Linux/Wayland-only stow packages: hypr waybar gtk qt fontconfig + wallpaper
├── mac/                   # macOS-only stow packages (placeholder — empty today)
├── docs/                  # design docs, plans, install.flow.mmd
├── dog/ utility/          # competitive-programming templates (not stowed)
├── fonts/ skills/         # shared: fonts symlinked, agent skill submodules
└── zsh/ tmux/ nvim/ kitty/ alacritty/ ideavim/ opencode/ xxh/   # stowed on every platform
```

Stow mention in the body becomes: `Stow symlinks common configs into $HOME on every platform (`zsh tmux nvim kitty alacritty ideavim opencode xxh`), plus Linux-only packages (`hypr waybar gtk qt fontconfig`) via `stow -d linux` — skipped on macOS.`

"info" section: remove nothing cross-platform; keep alacritty/kitty/tmux/zsh entries as-is.

- [ ] **Step 2: script/README.md edits.**
  - Line 15 tree: `├── 2. stow   # common pkgs everywhere (zsh tmux nvim kitty alacritty ideavim opencode xxh); mac skips, non-mac also stows linux/: hypr waybar gtk qt fontconfig`
  - Line ~71 mac.sh entry: delete the sentence `fnm is intentionally not in the Brewfile — it's installed by setup_programing.sh.`; replace with `Brewfile is the single source of mac packages — setup_basic.sh's mac branch only bootstraps brew.`
  - Execution-order tree: add `stow -d linux <pkgs>` to step 2 line and add `└── ...) setup_rtk.sh` already present — verify order tree matches install.sh (git identity, fonts before zsh, rtk last); fix any drift found.

- [ ] **Step 3: docs/install.flow.mmd fixes.**
  - Line 39 `Stow` node: `"<b>stow</b> zsh tmux nvim kitty alacritty ideavim opencode xxh<br/>+ stow -d linux: hypr waybar gtk qt fontconfig (non-mac)"`
  - Line 55 `Prog` node: replace `install_fnm (pacman/brew/curl)<br/>rustup + SDKMAN curl scripts<br/>` with `mise: go/java/node/rust from mise.toml<br/>`
  - Add missing steps between Stow and Fonts: a `GitID["<b>setup_git.sh</b><br/>interactive user.name/email"]` node and wire `Stow --> GitID --> MacDefaults OR S4`; add `RTK["<b>setup_rtk.sh</b><br/>rtk init -g --opencode"]` node after Skills, wire `Skills --> RTK --> Done`.

- [ ] **Step 4: Verify no stale references**

```bash
rg -n 'fnm|SDKMAN' --glob '!.git' --glob '!skills' . ; rg -ln 'stow alacritty gtk' --glob '!.git' --glob '!docs/superpowers' README.md docs/install.flow.mmd script/README.md
```

Expected: no `fnm/SDKMAN` outside historical spec/plan docs; no `stow alacritty gtk` old list outside the spec.

- [ ] **Step 5: Commit**

```bash
git add README.md script/README.md docs/install.flow.mmd && git commit -m "docs: sync README/script docs/flow diagram with new layout and mise"
```

---

### Task 6: End-to-end verification on this machine

**Files:** none modified (read-only checks + one idempotent run)

**Interfaces:**
- Consumes: everything above; validated before touching the new MacBook

- [ ] **Step 1: Rename integrity**

```bash
git status --short; git diff --stat HEAD~5..HEAD | tail -3
```

Expected: clean tree; lots of `R` renames in stat.

- [ ] **Step 2: Shellcheck all touched scripts**

```bash
shellcheck install.sh script/setup_basic.sh script/setup_os/mac.sh
```

Expected: clean.

- [ ] **Step 3: Stow dry-run both groups**

```bash
cd ~/dotfiles
stow -n -v zsh tmux nvim kitty alacritty ideavim opencode xxh 2>&1 | rtk tail -5
stow -n -d linux hypr waybar gtk qt fontconfig 2>&1 | rtk tail -5
```

Expected: exit 0; output only shows links whose targets already point at us (or nothing). No `.config/hypr` conflict lines.

- [ ] **Step 4: Idempotent re-run**

```bash
./install.sh --update
```

Expected: completes; refreshes zsh plugins + skills; no stow/package steps run (`--update` skips them — that is by design; stow was dry-run-verified in Step 3 instead).

- [ ] **Step 5: Wallpaper path still valid after move**

```bash
ls -la ~/dotfiles/linux/wallpaper/background-nagato.jpg
rg -n 'dotfiles/wallpaper' -g '!.git' . || echo "no stale refs"
```

Expected: file exists; "no stale refs".

- [ ] **Step 6: Final commit if anything drifted**

```bash
git status --short
```

Expected: empty. If not empty, investigate before proceeding — never commit unexplained files.
