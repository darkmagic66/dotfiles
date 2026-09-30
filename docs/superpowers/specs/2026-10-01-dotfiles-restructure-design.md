# Dotfiles Restructure — Platform Split + Cleanup (Stow)

Date: 2026-10-01
Status: approved design, pending implementation
Manager: GNU Stow (chezmoi evaluated, rejected for now — two machines, symlink-only needs)

## Problem

Repo grew Linux-only configs at root (`hypr`, `waybar`, `gtk`, `qt`, `fontconfig`, `wallpaper`) while macOS support was added (`Brewfile`, `setup_os/mac.sh`, `setup_mac.sh`). Issues:

1. `install.sh` stows Linux-only dirs on macOS — dead symlinks on the M5.
2. Package duplication: `setup_basic.sh` COMMON list overlaps `Brewfile` (git, zsh, stow, tmux, jq, eza, mise, nvim, kitty installed twice via two sources of truth).
3. Root clutter: `plan.md` (unfinished skills-migration plan), `install.flow.mmd` (drifted — still says fnm/rustup/SDKMAN), `ZSH.md`, `HYPRSUNSET-MIRROR-CTM.md`.
4. Docs drift: `script/README.md` stow list + `install.flow.mmd` out of sync with scripts.

## Target layout

```
dotfiles/
├── install.sh README.md Brewfile mise.toml .stow-local-ignore .gitignore .gitmodules
├── zsh/ tmux/ nvim/ kitty/ alacritty/ ideavim/ opencode/ xxh/   # stowed everywhere
├── fonts/            # shared, symlinked by setup_fonts.sh
├── script/           # setup scripts (unchanged structure)
├── skills/           # agent skill submodules (unchanged)
├── dog/ utility/     # competitive programming, not stowed (referenced from ~/coding/prac)
├── docs/             # plan.md, install.flow.mmd, ZSH.md, HYPRSUNSET-MIRROR-CTM.md, specs/
├── linux/            # stow target dir: hypr waybar gtk qt fontconfig (+ wallpaper stays raw path)
└── mac/              # empty placeholder (.gitkeep), future mac-only stow target
```

Common stow packages stay at repo root (`zsh/ tmux/ ...`) so `stow <pkg>` keeps working unchanged; platform dirs are separate stow target dirs (`-d linux` / `-d mac`).

## Changes

### 1. Moves (all `git mv`, history preserved)

- `hypr waybar gtk qt fontconfig` → `linux/`
- `wallpaper` → `linux/wallpaper` (hypr configs reference it by absolute `$HOME` path already — verify and fix any relative refs)
- `plan.md install.flow.mmd ZSH.md HYPRSUNSET-MIRROR-CTM.md` → `docs/`
- `mac/.gitkeep` created

### 2. install.sh — distro-aware stow

```bash
STOW_COMMON="zsh tmux nvim kitty alacritty ideavim opencode xxh"
stow $STOW_COMMON
if [ "$DISTRO" != "mac" ]; then
  stow -d linux hypr waybar gtk qt fontconfig
fi
# mac placeholder: no packages yet; add here when mac/ gains content
```

### 3. Package dedupe — Brewfile becomes single source of truth on mac

- Add missing COMMON items to `Brewfile`: htop fd fzf bat ripgrep zoxide git-delta lazygit tree-sitter-cli tldr asciinema zip unzip wget
- `setup_basic.sh` mac branch: only bootstrap Homebrew (install if missing) + `brew update`; drop the duplicate `brew install "${COMMON_PACKAGES[@]}"` — `setup_os/mac.sh`'s `brew bundle` covers everything
- Linux branches unchanged

### 4. .stow-local-ignore

Add: `linux`, `mac`, `docs` — bare `stow .` from repo root stays safe (never symlinks platform/docs dirs).

### 5. Docs sync

- `README.md`: new layout tree, stow section describes common + `-d linux`, note `mac/` placeholder
- `script/README.md`: stow list update, fix `setup_programing.sh` description (fnm/rustup/SDKMAN → mise)
- `install.flow.mmd`: fnm/rustup/SDKMAN → mise, add missing git-identity + rtk steps, new stow structure
- `plan.md` moves to docs/ as-is (unfinished skills migration — separate future work)

## Non-goals

- No chezmoi/yadm migration (rejected: symlink model sufficient, avoids double refactor)
- No new mac window-manager configs (mac/ stays empty placeholder)
- No skills-migration execution (plan.md stays a doc)
- No CachyOS behavior change: same packages, same links, new paths only

## Verification

1. `git status` — only renames + intended edits
2. Dry-run stow on this machine: `stow -n -v` common pkgs + `stow -n -d linux ...` — no conflicts, existing links re-point correctly (`stow --restow`)
3. Shellcheck `install.sh` + edited scripts
4. Grep hypr/waybar configs for wallpaper path refs — fix to new location if relative
5. `./install.sh --update` on this machine — idempotent pass, no failures

## Acceptance

- macOS install path: brew bundle installs everything once; zero Linux-only stow links on mac
- Linux install path: identical end state to before (packages, symlinks, services)
- Root contains only: cross-platform stow packages, shared dirs, install.sh, Brewfile, mise.toml, README, dotfiles
- All docs match actual script behavior
