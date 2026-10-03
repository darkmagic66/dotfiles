# dotfiles — keyboard-driven

Mouse optional. Compositor, terminal, multiplexer, editor, launcher, and
pointer all answer to keys. Linux runs Hyprland (`SUPER`), macOS runs
AeroSpace (`Alt` — see translation note), everything else is shared.

## Keyboard map

### Linux: Hyprland (`SUPER` = Windows key)

| Keys | Action |
|---|---|
| `SUPER+T` | kitty terminal |
| `SUPER+W` | close window |
| `SUPER+E` | yazi file manager |
| `SUPER+R` | fuzzel launcher |
| `SUPER+V` | toggle float |
| `SUPER+M` | shutdown / exit menu |
| `SUPER+H/J/K/L` | focus left / down / up / right |
| `SUPER+1..0` | workspaces 1–10 |
| `SUPER+SHIFT+1..0` | move window to workspace |
| `SUPER+scroll` | cycle workspaces |
| `SUPER+drag / right-drag` | move / resize window |

### macOS: AeroSpace (`Alt` = Option)

Hyprland `SUPER` is macOS `Cmd`, which apps own (`Cmd+W` closes tabs,
`Cmd+1-9` switches browser tabs). Grabbing it system-wide breaks every app,
so the same map lives on `Alt` instead. Kitty's `Cmd+T` and the like stay
untouched.

| Keys | Action |
|---|---|
| `Alt+Enter` | kitty terminal |
| `Alt+W` | close window |
| `Alt+E` | Finder |
| `Alt+V` | toggle float/tiling |
| `Alt+F` | fullscreen |
| `Alt+H/J/K/L` | focus left / down / up / right |
| `Alt+SHIFT+H/J/K/L` | move window |
| `Alt+1..9` | workspaces 1–9 |
| `Alt+SHIFT+1..9` | move window to workspace |
| `Alt+Tab` | last workspace |
| `Alt+/` `Alt+,` | tiles / accordion layout |
| `Alt+-` `Alt+=` | resize smarter ∓/±50 |

Config: `mac/aerospace/.aerospace.toml` (stowed mac-only, auto-reloads on
save). Needs Accessibility permission once.

### Shared everywhere

**tmux** (`Ctrl-a` prefix): `prefix+I` installs plugins, `Ctrl-h/j/k/l`
moves between vim splits and tmux panes seamlessly (vim-tmux-navigator).

**nvim** (NvChad, `Space` leader): `;` opens cmdline, `jk` escapes insert
mode, dashboard keys `ff` find file / `fo` recent / `fw` live grep / `ma`
bookmarks / `th` themes / `ch` cheatsheet, `Space+z` zen mode.

**shell** (zsh, vi mode): `Ctrl+R` atuin history search, `z`/`zi` zoxide
jump, `fzf` + `eza` + `bat` + `ripgrep` wired through completions.

**pointer without mouse** (Neru, mac): `Cmd+Shift+Space` hints (type label
to click), `Cmd+Shift+C` recursive grid, `Cmd+Shift+G` grid jump,
`Cmd+Shift+B` bisect, `Cmd+Shift+S` scroll mode. Config:
`mac/neru/.config/neru/config.toml` (stowed mac-only).

**keys** (mac): Caps Lock → Control via Karabiner-Elements
(`mac/karabiner/`, stowed mac-only). Fn keys act as F-keys, text
substitutions off, key repeat fast, double-click threshold slowest.

**launcher** (mac): Raycast. Per-app global hotkeys set in Raycast itself
(Root Search → app → `Cmd+K` → Configure Application → Record Hotkey);
nothing scriptable lives in this repo for those.

## Install

```bash
git clone --recursive https://github.com/darkmagic66/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap
```

`./bootstrap` with no arguments runs the **full flow** (packages → git identity → stow → mac defaults → fonts → zsh → toolchains → skills → rtk). It is idempotent — safe to re-run anytime.

`./bootstrap --update` is a fast re-sync: it skips the slow package-manager / git-identity / stow / mac-defaults / fonts steps and refreshes zsh plugins + skill submodules (`setup_zsh.sh --update` + `setup_skills.sh --update`).

`./install.sh` still works — it is now a 3-line shim that `exec`s `./bootstrap`, but it is deprecated; use `./bootstrap` directly.

### Subcommands

| Command | What it does |
|---|---|
| `./bootstrap` | Full install flow (everything below, in order) |
| `./bootstrap --update` | Full flow in update mode (packages/stow/fonts skipped, plugins+skills refreshed) |
| `./bootstrap packages` | Install packages only: `manifest.yaml` → per-OS adapter |
| `./bootstrap config` | Stow only: symlinks + role resolution (no packages) |
| `./bootstrap ai` | Skills + rtk setup (`setup_skills.sh` + `setup_rtk.sh`) |
| `./bootstrap ai list` | List installed skills (personal/external split view) |
| `./bootstrap ai update` | Update skill submodules (`git submodule update --remote --merge`) |
| `./bootstrap ai status` | Skill submodule status (`git submodule status`) |
| `./bootstrap list` | Print the manifest groups that apply to this machine + role |

`just` shortcuts (see `justfile`): `just install`, `just update`, `just config`, `just packages`, `just plan`, `just skills-update`, `just upgrade` (pull + re-sync).

## Where the packages come from

`packages/manifest.yaml` is the **single source of truth** for every package, on every OS. No package lists live in scripts anymore.

Groups: `common` (all machines), `linux` (pacman, arch family), `macos_casks` + `macos_extra` (brew), `windows` (winget — sketch), and role groups `role_personal` / `role_company` (personal-only tools live there, e.g. Aldente, AeroSpace, Karabiner, Neru).

Each OS adapter reads the manifest and installs with its native package manager:

| Adapter | OS | Mechanism |
|---|---|---|
| `bootstrap.d/lib/adapters/pacman.sh` | arch family | pacman (manifest `common` + `linux`); AUR extras: `visual-studio-code-bin`, `python-xxh` (auto paru/yay); system services |
| `bootstrap.d/lib/adapters/brew.sh` | macOS | brew formulas (`common` + `macos_extra`, minus `curl` — system curl kept) and casks (`macos_casks` + `role_personal`); installs brew itself if missing; per-package warn-and-continue, one bad package never aborts the run |
| `bootstrap.d/lib/adapters/debian.sh` | Debian family | apt + zed installer + VS Code MS apt repo |
| `bootstrap.d/lib/adapters/fedora.sh` | Fedora | dnf + zed installer + VS Code MS dnf repo |
| `bootstrap.d/lib/adapters/win.sh` | Windows | winget sketch — prints, does not run yet |

### Roles & hosts

Machines have a role (`personal` / `company`) resolved at stow time via `bootstrap.d/lib/hosts.sh`:

1. persisted machine-local file `~/.config/dotfiles/role` (untracked) wins,
2. else the `HOST_ROLE` table keyed by hostname,
3. else an interactive prompt (once); the answer is persisted.

`role_personal` / `role_company` manifest groups filter packages (brew) and `roles/<role>/` stow packages follow the role. The role file persists across runs, so you only pick once per machine.

**On a new machine:** first thing after cloning, edit the `HOST_ROLE` table in `bootstrap.d/lib/hosts.sh` — add your hostname with the right role — then run `./bootstrap`.

## What gets installed

### Packages (per OS, from `packages/manifest.yaml`)
- **common (all machines)**: git, zsh, stow, tmux, jq, eza, gnupg, neovim, mise, atuin, htop, fd, fzf, zoxide, bat, ripgrep, zip, unzip, curl, wget, git-delta, tree-sitter-cli, lazygit
- **arch family**: kitty, waybar, yazi, awww, brightnessctl, wl-clipboard, powerline-fonts, ncdu, playerctl, udisks2, blueman, zed, fuzzel, bitwarden + AUR (visual-studio-code-bin, python-xxh) + services
- **macOS**: formulas (common + xxh, tldr, asciinema, `anomalyco/tap/opencode-v2`; system curl kept) + casks (kitty, firefox, brave-browser, bitwarden, visual-studio-code, zed, notion, raycast) + `role_personal` only (aldente, karabiner-elements, `nikitabobko/tap/aerospace`, `y3owk1n/tap/neru`)
- **Debian/Fedora**: zed installer + Microsoft's apt/dnf repo for vscode

### Editors
- **nvim** (NvChad on lazy.nvim)
- **zed**
- **vscode** (Visual Studio Code)

### Other setup
- **Stow** symlinks common configs into $HOME on every platform (`zsh tmux nvim kitty alacritty ideavim opencode xxh`), Linux-only packages (`hypr waybar gtk qt fontconfig`) via `stow -d linux` (skipped on macOS), mac-only packages (`aerospace karabiner neru`) via `stow -d mac` (skipped on Linux). `roles/<role>/` stow packages follow the resolved machine role.
- **zsh** (vim style): plugins (powerlevel10k, autosuggestions, completions, syntax-highlighting, vi-mode) + tmux plugin manager + `chsh -s zsh`; brew shellenv eval'd on macOS so `/opt/homebrew/bin` is on PATH
- **xxh**: portable shell over ssh — `~/.config/xxh/config.xxhc` pins `+s zsh`, powerlevel10k + zoxide plugins; use `xxh <host>` instead of `ssh <host>` (target hosts: Linux x86_64)
- **Fonts** from `fonts/` symlinked into the OS font directory
- **macOS defaults** (Finder/trackpad/keyboard/screenshots/double-click) on mac only; Night Shift, display scaling, True Tone, and auto-brightness stay manual (no scriptable keys, no third-party tools by policy)
- Programming toolchains via `setup_programing.sh`: mise (go/java/node/rust), GitNexus, rtk
- Agent skills via `setup_skills.sh`: skills submodules symlinked into `~/.config/opencode/skills/`, `~/.claude/skills/`, `~/.codex/skills/`, `~/.agents/skills/`

### Scripts (under `script/`)
- `setup_basic.sh` — thin dispatcher: sources `bootstrap.d/lib/adapters/*.sh` (self-guarded) and calls the matching adapter's install function. Package names come from `packages/manifest.yaml`.
- `setup_git.sh` — interactive git `user.name`/`user.email`
- `setup_fonts.sh`, `setup_zsh.sh`, `setup_mac.sh`, `setup_programing.sh`, `setup_skills.sh`, `setup_rtk.sh` — see [`script/README.md`](script/README.md)

## Secrets

**Tokens, keys, and passwords NEVER go into this Git repo.** Machine-local secrets live in *untracked* files only:

- `~/.config/zsh/.zshrc.local` — sourced by `zsh/.zshrc` (env vars, exports, tokens)
- `~/.config/dotfiles/role` — the machine-local role cache (never tracked)

Nothing secret is read from any tracked file.

## Layout

```
~/dotfiles/
├── bootstrap               # entry point (subcommands: packages|config|ai|--update)
├── bootstrap.d/lib/        # shared libs: common, manifest, hosts, full, config, ai
│   └── adapters/           # pacman.sh, brew.sh, debian.sh, fedora.sh, win.sh (sketch)
├── packages/
│   └── manifest.yaml       # single source of truth for all packages, all OSes
├── roles/                  # per-role stow packages (personal/company; gitkeep-only today)
├── install.sh              # 3-line shim → ./bootstrap (deprecated)
├── mise.toml               # toolchain versions for setup_programing.sh
├── script/                 # setup_*.sh thin steps (see script/README.md)
├── linux/                  # Linux/Wayland-only stow packages: hypr waybar gtk qt fontconfig + wallpaper
├── mac/                    # macOS-only stow packages: aerospace karabiner neru
├── docs/                   # design docs, specs, install.flow.mmd, M5-RUNBOOK.md
├── dog/ utility/           # competitive-programming templates (not stowed)
├── fonts/ skills/          # shared: fonts symlinked, agent skill submodules
└── zsh/ tmux/ nvim/ kitty/ alacritty/ ideavim/ opencode/ xxh/   # stowed on every platform
```

See [`script/README.md`](script/README.md) for the detailed execution order and the adapter pattern, and [`docs/M5-RUNBOOK.md`](docs/M5-RUNBOOK.md) for the new-machine runbook.

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
