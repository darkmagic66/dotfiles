# dotfiles — agent runbook

You are an agent working in this repo. Follow the tasks below exactly.
Each task ends with a verify step — run it, read the output, do not skip.
Repo root is `~/dotfiles` (clone target). All paths below are relative to it.

## Hard policies (never violate)

1. **Native macOS only, no new tools**, unless the user explicitly asks.
   Night Shift / display scaling / True Tone / auto-brightness stay manual
   (documented below). No CLI workarounds for them.
2. **Confirm layer + behavior before writing.** One clarifying question up
   front beats a revert commit. Past cycles (kitty-vs-system,
   CLI-vs-native, hidutil-vs-Karabiner) cost trust.
3. **Terse user, misclicks happen.** Re-asking is supported; do not treat a
   first answer as sacred when the user says misclick.
4. **Secrets NEVER enter this repo.** Tokens/keys/passwords live only in
   untracked files: `~/.config/zsh/.zshrc.local`,
   `~/.config/dotfiles/role`. Nothing secret is read from any tracked file.
5. **Chat output terse** (caveman-full); persisted files stay normal prose.
   Load `karpathy-guidelines` before touching shell/config code and
   `verification-before-completion` before claiming anything complete.

## Task 1 — new machine install

```bash
git clone --recursive https://github.com/darkmagic66/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

Then FIRST: open `bootstrap.d/lib/hosts.sh`, add the hostname to the
`HOST_ROLE` table with role `personal` or `company`. Then:

```bash
./bootstrap
```

`./bootstrap` runs the full flow: packages → git identity → stow → mac
defaults → fonts → zsh → toolchains → skills → rtk. It is idempotent —
safe to re-run anytime. Per-package warn-and-continue holds: one bad
formula/cask never aborts the run.

Verify: re-run `./bootstrap packages`; expect exit 0 with no new installs.
Then `./bootstrap list`; expect the manifest groups for this machine + role.

`./install.sh` is a deprecated 3-line shim → `./bootstrap`. Never use it.

### Subcommands (use these, not ad-hoc script calls)

| Command | Effect |
|---|---|
| `./bootstrap` | Full install flow, in order |
| `./bootstrap --update` | Fast re-sync: skips packages/stow/fonts, refreshes zsh plugins + skills |
| `./bootstrap packages` | Packages only: `manifest.yaml` → per-OS adapter |
| `./bootstrap config` | Stow only: symlinks + role resolution, no packages |
| `./bootstrap ai` | Skills + rtk setup |
| `./bootstrap ai list` | Installed skills (personal/external split) |
| `./bootstrap ai update` | `git submodule update --remote --merge` for skills |
| `./bootstrap ai status` | `git submodule status` for skills |
| `./bootstrap list` | Manifest groups applying to this machine + role |

`just` shortcuts mirror these (`justfile`): `just install`, `just update`,
`just config`, `just packages`, `just plan`, `just skills-update`,
`just upgrade` (pull + re-sync).

## Task 2 — add or move a package

`packages/manifest.yaml` is the single source of truth. No package lists
live in scripts. Group semantics (enforced by adapters in
`bootstrap.d/lib/adapters/`):

| Group | Installed by | Rule |
|---|---|---|
| `common` | brew formulas + pacman + apt + dnf | Name must exist in **all four** managers. If apt/dnf lack it, do NOT put it here. |
| `linux` | pacman (arch family) | Arch-only names (`-bin` AUR names do NOT go here; AUR extras stay in `pacman.sh`) |
| `macos_extra` | brew formulas | Mac-only formula additions (e.g. `yazi` — also in `linux` because apt/dnf lack it) |
| `macos_casks` | brew casks, all macs | GUI apps every mac gets (company M3 included) |
| `role_personal` | brew casks, personal macs only | System-level tools company M3 must not get unasked (AeroSpace, Karabiner, Neru, Aldente) |
| `role_company` | (empty today) | Company-mac extras |
| `windows` | winget sketch | Prints only, does not install yet |

Steps:

1. Confirm the package name on the target manager BEFORE editing:
   `https://formulae.brew.sh/api/formula/<name>.json` (200 = exists),
   same under `/api/cask/` for casks.
2. Edit `packages/manifest.yaml`: item lines are exactly `  - <name>`
   (2 spaces, dash, space). Trailing `# comment` allowed.
3. If the package is user-facing on mac, update the macOS line under
   "What gets installed" below to match.
4. Verify with the repo's own parser (exact commands):
   ```bash
   source bootstrap.d/lib/manifest.sh
   export DOTFILES_DIR=~/dotfiles
   manifest_packages macos_extra
   manifest_packages macos_casks
   { manifest_packages common; manifest_packages macos_extra; } | tr ' ' '\n' | sort | uniq -d
   ```
   Expect: both groups list your addition, dupe check prints nothing.

## Task 3 — change stowed config

Stow packages and their gates:

- Every platform: `zsh tmux nvim kitty alacritty ideavim opencode xxh git zed yazi` (`git` = delta pager config at `~/.config/git/config`; machine-local identity stays in real `~/.gitconfig`)
- Linux only (`stow -d linux`, skipped on macOS): `hypr waybar gtk qt fontconfig`
- Mac only (`stow -d mac`, skipped on Linux): `aerospace karabiner neru`
- `roles/<role>/` follows the resolved machine role.

Role resolution order (`bootstrap.d/lib/hosts.sh`): persisted
`~/.config/dotfiles/role` wins → `HOST_ROLE` hostname table → one-time
interactive prompt (answer persisted). The file persists across runs; each
machine picks once.

Verify: run `./bootstrap config`, then confirm the symlink exists, e.g.
`ls -la ~/.config/aerospace` (mac) points into the repo.

GUI-rewrite hazard: Karabiner GUI rewrites kill the symlinked
`karabiner.json`. Always edit the repo file; if the GUI rewrote it,
re-adopt the minimized rewrite and confirm the caps mapping survived.

## Task 4 — macOS system settings

Scripted (in `script/setup_mac.sh`, mac only): Finder/trackpad/keyboard/
screenshots/double-click threshold (working value `1.7`, higher = more
forgiving), `expose-group-apps` for Mission Control under AeroSpace.

Manual (no scriptable keys, by policy — give the user Settings paths,
do not invent CLI): Night Shift, display scaling ("More Space"), True Tone,
auto-brightness, Raycast per-app hotkeys (Root Search → app → `Cmd+K` →
Configure Application → Record Hotkey), Accessibility grant for AeroSpace,
Input Monitoring grant for Karabiner.

AeroSpace config: `mac/aerospace/.aerospace.toml`, auto-reloads on save.
`start-at-login` stays `false` until the user is happy.

## What gets installed (from `packages/manifest.yaml`)

- **common (all machines)**: git, zsh, stow, tmux, jq, eza, gnupg, neovim, mise, atuin, htop, fd, fzf, zoxide, bat, ripgrep, zip, unzip, curl, wget, git-delta, tree-sitter-cli, lazygit, just, steam
- **arch family**: kitty, waybar, yazi, awww, brightnessctl, wl-clipboard, powerline-fonts, ncdu, playerctl, udisks2, blueman, zed, fuzzel, bitwarden, obs-studio + AUR (visual-studio-code-bin, python-xxh) + services
- **macOS**: formulas (common + yazi, xxh, tldr, asciinema, `anomalyco/tap/opencode-v2`; system curl kept) + casks (kitty, firefox, brave-browser, bitwarden, visual-studio-code, zed, notion, raycast, orbstack, obs, steam, vorssaint) + `role_personal` only (aldente, karabiner-elements, `nikitabobko/tap/aerospace`, `y3owk1n/tap/neru`)
- **Debian/Fedora**: zed installer + Microsoft's apt/dnf repo for vscode; `common` name maps apply (`fd`→`fd-find`, `just`→`rust-just`)

Editors: nvim (NvChad on lazy.nvim), zed, vscode.

Other setup: zsh plugins (powerlevel10k, autosuggestions, completions,
syntax-highlighting, vi-mode) + tpm + `chsh -s zsh`; brew shellenv first in
`.zshrc` so GUI-launched processes inherit `/opt/homebrew/bin`; tmux.conf
carries a guarded `set-environment -g PATH` for GUI-spawned servers;
`~/.config/xxh/config.xxhc` pins `+s zsh` (use `xxh <host>`, Linux x86_64
targets); fonts symlinked from `fonts/`; toolchains via
`setup_programing.sh` (mise go/java/node/rust, GitNexus, rtk); skills via
`setup_skills.sh` into `~/.config/opencode/skills/`,
`~/.claude/skills/`, `~/.codex/skills/`, `~/.agents/skills/`; graphify
knowledge-graph CLI + `/graphify` skill via `setup_graphify.sh` (uv from mise).
`script/` holds thin `setup_*.sh` steps (see `script/README.md`).

## Keyboard map (reference — mouse optional)

Linux runs Hyprland (`SUPER` = Windows key). macOS runs AeroSpace on `Alt`:
`SUPER` is macOS `Cmd`, which apps own (`Cmd+W`, `Cmd+1-9`), so the same map
lives on `Alt` instead. Kitty `Cmd+T` and the like stay untouched.

| Linux (Hyprland) | macOS (AeroSpace) | Action |
|---|---|---|
| `SUPER+T` | `Alt+Enter` | kitty terminal |
| `SUPER+W` | `Alt+W` | close window |
| `SUPER+E` (yazi) | `Alt+E` (Finder) | file manager |
| `SUPER+R` | — (Raycast) | launcher |
| `SUPER+V` | `Alt+V` | toggle float |
| `SUPER+M` | — | shutdown / exit menu |
| `SUPER+H/J/K/L` | `Alt+H/J/K/L` | focus left/down/up/right |
| `SUPER+1..0` | `Alt+1..9` | workspaces |
| `SUPER+SHIFT+1..0` | `Alt+SHIFT+1..9` | move window to workspace |
| | `Alt+SHIFT+H/J/K/L` | move window |
| | `Alt+F` | fullscreen |
| | `Alt+Tab` | last workspace |
| | `Alt+/` `Alt+,` | tiles / accordion layout |
| | `Alt+-` `Alt+=` | resize smarter ∓/±50 |

Shared everywhere — tmux (`Ctrl-a` prefix, `prefix+I` installs plugins,
`Ctrl-h/j/k/l` seamlessly moves vim↔tmux via vim-tmux-navigator); nvim
(`Space` leader, `;` cmdline, `jk` escape, dashboard `ff`/`fo`/`fw`/`ma`/
`th`/`ch`, `Space+z` zen); shell (vi mode, `Ctrl+R` atuin, `z`/`zi`
zoxide, fzf+eza+bat+ripgrep); Neru pointer (mac: `Cmd+Shift+Space` hints,
`Cmd+Shift+C` grid, `Cmd+Shift+G` jump, `Cmd+Shift+B` bisect,
`Cmd+Shift+S` scroll; config `mac/neru/.config/neru/config.toml`, hint
command must be `hints --action left_click`); keys (mac: Caps→Ctrl via
Karabiner, Fn-as-F-keys, fast repeat, substitutions off).

## Layout

```
~/dotfiles/
├── bootstrap               # entry point (packages|config|ai|--update)
├── bootstrap.d/lib/        # common, manifest, hosts, full, config, ai
│   └── adapters/           # pacman.sh, brew.sh, debian.sh, fedora.sh, win.sh (sketch)
├── packages/
│   └── manifest.yaml       # single source of truth, all packages, all OSes
├── roles/                  # per-role stow packages (personal/company; gitkeep-only today)
├── install.sh              # deprecated shim → ./bootstrap
├── mise.toml               # toolchain versions for setup_programing.sh
├── script/                 # setup_*.sh thin steps (see script/README.md)
├── linux/                  # Linux-only stow: hypr waybar gtk qt fontconfig + wallpaper
├── mac/                    # mac-only stow: aerospace karabiner neru
├── docs/                   # design docs, specs, handoffs, M5-RUNBOOK.md
├── dog/ utility/           # competitive-programming templates (not stowed)
├── fonts/ skills/          # fonts symlinked, agent skill submodules
└── zsh/ tmux/ nvim/ kitty/ alacritty/ ideavim/ opencode/ xxh/ git/ zed/ yazi/   # stowed everywhere
```

Runbook: `docs/M5-RUNBOOK.md`. Execution order + adapter pattern:
`script/README.md`.

## Info

* editor: NVChad (on lazy.nvim) + zed + vscode
* shell: zsh — vim style
* shell styling: manual (powerlevel10k)
* terminal emulator: kitty (mac), kitty/alacritty (linux)
* terminal multiplexer: tmux (`Ctrl-a` prefix)
* window management: Hyprland (linux) / AeroSpace (mac)
* keyboard remap: Karabiner-Elements (mac)
* mouseless pointer: Neru (mac)
* launcher: Raycast (mac), fuzzel (linux)
* dotfile manager: stow
