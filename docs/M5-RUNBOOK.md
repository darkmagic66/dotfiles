# M5 runbook — MacBook-M5 personal (macOS)

Exact steps for the **personal M5 mac**, step by step. Architecture v2 (manifest + bootstrap + adapters) with `ROLE=personal`.

> **Status 2026-10-01 evening:** mac run has started live on the M5 — several fresh-mac failures found and fixed (CLT first, bash-3.2 `case` hosts table, alacritty cask dropped, stow self-install, defaults warn-and-continue, per-package brew installs). Windows install is a separate sketch (`bootstrap.d/lib/adapters/win.sh` only prints); company machines just resolve to a different role.

## 0. Prereqs
- macOS on the M5, network reachable.
- You will type the sudo/password prompts brew + zed/chsh ask for.
- **Command Line Tools first** — on a fresh mac, `git` is only a shim that
  asks for Xcode/CLT. Install it before anything (GUI dialog appears, takes
  a few minutes):

```bash
xcode-select --install
```

Verify: `xcode-select -p` prints `/Library/Developer/CommandLineTools` and
`git --version` works *without* the Xcode popup.

## 1. Clone

```bash
git clone --recursive https://github.com/darkmagic66/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

`--recursive` matters: the four skill submodules under `skills/` (superpowers, mattpocock-skills, caveman, skill-tissue-skills) must land with the clone, or `bootstrap ai` will re-init them later anyway.

## 2. Edit `bootstrap.d/lib/hosts.sh` FIRST

The `_host_role_for` case table ships with **placeholder** rows (`macbook-m3` / `macbook-m5` / `windows-pc`). Replace the `macbook-m5` row with the M5's **real hostname** (`scutil --get ComputerName` or `hostname`) and keep `personal`:

```bash
_host_role_for() {
  case "$1" in
    thinkpad-p14s) printf 'personal\n' ;;   # verified: real hostname
    macbook-m3)    printf 'company\n' ;;
    <real-m5-hostname>) printf 'personal\n' ;;
    windows-pc)    printf 'personal\n' ;;
  esac
}
```

NOTE: plain `case`, NOT `declare -A` — macOS ships bash 3.2, which has no associative arrays.

Why here and not later: role resolution falls back to an interactive prompt (fine), but editing the table keeps it deterministic — role filtering (brew casks, `roles/<role>` stow) uses it before anything installs.

## 3. Run bootstrap

```bash
./bootstrap
```

## 4. What to expect (sequential — verbatim per full.sh + brew adapter)

1. **Internet check**: `curl https://github.com` must succeed, else exit 1.
2. **OS detect**: `Detected OS: macOS`.
3. **Packages** (`script/setup_basic.sh` → `bootstrap.d/lib/adapters/brew.sh`):
   - **brew bootstrap**: brew install script runs only when `brew` is missing; otherwise skipped.
   - **shellenv eval**: `/opt/homebrew/bin/brew shellenv` (fallback `/usr/local`) is eval'd.
   - **update** runs.
   - **Formulas** (per-package `brew install`, one failure warns and continues) from manifest `common` + `macos_extra`, **skip list `curl` explicitly** (system curl is kept): `git`/`zsh`/`stow`/`tmux`/`jq`/`eza`/`gnupg`/`neovim`/`mise`/`atuin`/`htop`/`fd`/`fzf`/`zoxide`/`bat`/`ripgrep`/`zip`/`unzip`/`wget`/`git-delta`/`tree-sitter-cli`/`lazygit`/`xxh`/`tldr`/`asciinema`/`anomalyco/tap/opencode-v2`.
   - **Casks** (per-cask `brew install --cask`, one failure warns and continues) from manifest `macos_casks` + `role_personal` since `ROLE=personal`: `kitty`, `firefox`, `visual-studio-code`, `zed`, `notion`, `raycast`, **+ `aldente`, `karabiner-elements`, `nikitabobko/tap/aerospace`, `y3owk1n/tap/neru` (personal role only — this is where Aldente shows up; a company machine would NOT get it)**. `alacritty` is intentionally NOT a cask (Gatekeeper-blocked; kitty is the mac terminal — alacritty config still stows).
4. **git identity** (`setup_git.sh`): interactive `user.name`/`user.email` prompts if unset.
5. **Stow** (`bootstrap.d/lib/config.sh`): `resolve_role` prints `Resolved role: personal (host: …)` (or prompts once; answer persists to `~/.config/dotfiles/role`), then `stow -t "$HOME" zsh tmux nvim kitty alacritty ideavim opencode xxh`. On mac the `linux` packages (`hypr/waybar/…`) are skipped. This machine's `roles/` dirs are gitkeep-only today, so the stow step skips `roles/personal` until real content lands there.
6. **mac defaults** (`setup_mac.sh`): Finder/trackpad/keyboard/screenshots `defaults write …`.
7. **Fonts** (`setup_fonts.sh`): symlink `fonts/*` into `~/Library/Fonts/`.
8. **zsh** (`setup_zsh.sh`): clones plugins (powerlevel10k, autosuggestions, completions, syntax-highlighting, vi-mode) + **tpm**; prompts for **`chsh -s zsh`**.
9. **Toolchains** (`setup_programing.sh`): `mise install` provisions go/java/node/rust from `mise.toml`, then GitNexus (`mise exec -- npm install -g gitnexus`), then **rtk** (brew installed the mise binary; rtk via brew adapter, curl script as fallback).
10. **skills** (`setup_skills.sh`): init submodules + symlinks into `~/.config/opencode/skills/`, `~/.claude/skills/`, `~/.codex/skills/`, `~/.agents/skills/`.
11. **rtk** (`setup_rtk.sh`, LAST): `rtk init -g --opencode` installs the opencode plugin at `~/.config/opencode/plugins/rtk.ts`. rtk must already be in PATH.
12. **Done** banner with next steps printed.

## 5. After-install verification and manual fill-ins

- restart shell (`exec $SHELL`) — p10k runs its font/wizard prompt.
- **tmux**: open tmux, press `prefix` + `I` to install plugins.
- **nvim**: open nvim, run `:Mason` to install LSP servers.
- **opencode/claude/codex**: restart to pick up the freshly symlinked skills.
- `rtk status && rtk gain` should work (plugin already rewrites commands).
- **cross-check**, all after the run: `command -v brew zsh stow mise rtk xxh` all resolve; `brew list --formula | grep -E '^(curl|xh|zsh)'` — exactly one `zsh`, and **no `curl`** (skipped on purpose); `brew list --cask` includes `aldente`.
- **`./bootstrap` (idle re-run)** should be a no-op (idempotent) — no re-download, no re-chsh, no duplicate stow, same role resolved from `~/.config/dotfiles/role`.
- **`./bootstrap --update`** should refresh skill submodules + zsh plugins only, not reinstall brew packages.
- **`./bootstrap list`** prints the resolved package groups and role for this host.
- **`./bootstrap ai status`** lists the 4 skill submodules (personal/external split view).
- **`./bootstrap config`** — stow-only run for quick re-linking, no packages touched.
- Runbook-as-source-of-truth: **OPTIONAL** — if any brew/zed/chsh/mise manual step gets needed, it means the runbook misses something; fix the runbook or the adapter, not the workspace.

No `plan.md` and no Brewfile step here — brew pulls everything from `packages/manifest.yaml` (the retired `brew bundle` flow lives only in git history).

## 6. Secrets after install

- **tokens/keys/passwords NEVER go into the Git repo.**
- put machine-local secrets in untracked `~/.config/zsh/.zshrc.local` (sourced by `zsh/.zshrc`), not in any tracked file.
- `~/.config/dotfiles/role` is **also untracked** (machine-local cache, not config).

## 7. Known sketchy bits (mac run live since 2026-10-01 evening)

- **brew adapter on M5** has now executed for real (fresh-mac failures found: alacritty cask Gatekeeper-block, single-line abort skipping stow — both fixed with per-package warn-and-continue) — the shellenv path (`/opt/homebrew`) and non-cask/cask split are per the old installer's flow but the live run confirms the split works; per-package resilience now covers single bad formulas/casks.
- **zed + vsCode casks and config linking** — kitty/alacritty/ideavim storages are stowed; **vscode settings were never previously stowed on mac** — likely needs verification.
- **mac `roles/personal`** still empty (gitkeep-only) — the stow step will skip it silently this round; brew `role_personal` group is the only personal signal that fires today.
- repo assumption: `git clone --recursive` clone URL is the real https://github.com/darkmagic66/dotfiles.git (fixed 2026-10-01; no placeholder substitution needed).
