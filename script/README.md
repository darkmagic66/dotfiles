# Scripts

Called by `../install.sh` in order. Each script is standalone and idempotent (safe to re-run).

## Execution order

```
install.sh
├── 1. setup_basic.sh          # COMMON packages (all OS) + source setup_os/*.sh
│   └── setup_os/<distro>.sh   # distro-specific extras (self-guarded extensions)
│       ├── mac.sh             #   brew bundle (casks: vscode, zed, …)
│       ├── debian.sh          #   fd-find→fd symlink; zed installer; vscode MS apt repo
│       ├── arch.sh            #   pacman extras (waybar/yazi/awww/zed); yay auto-build; vscode-bin (AUR); services
│       └── fedora.sh            #   zed installer; vscode MS dnf repo
├── 2. stow                    # symlink dotfiles (alacritty hypr ideavim kitty nvim opencode tmux waybar zsh)
├── 3. setup_git.sh            # interactive git user.name/user.email (skipped in --update)
├── 3. setup_mac.sh            # macOS-only: Finder/trackpad/keyboard defaults (config, not packages)
├── 4. setup_fonts.sh         # symlink fonts into OS font dir
├── 5. setup_zsh.sh           # clone zsh plugins + tpm + chsh -s zsh
├── 6. setup_programing.sh    # mise (go/java/node/rust), GitNexus, rtk (OS-aware)
└── 7. setup_skills.sh        # init skill submodules + symlink skills into agent dirs
└── 8. setup_rtk.sh           # activate rtk for opencode (installs opencode plugin)
```

## `setup_os/` vs top-level `setup_*.sh`

- **`setup_os/<distro>.sh`** = installs **packages** for that distro family (pacman / brew / apt / dnf / AUR helper / curl installer). Sourced by `setup_basic.sh` via `source setup_os/*.sh` — one file per distro family, each self-guarded.
- **Top-level `setup_*.sh`** = other concerns: `setup_zsh.sh` (plugins + chsh), `setup_fonts.sh` (fonts), `setup_skills.sh` (agent skill submodules), `setup_programing.sh` (toolchains), `setup_mac.sh` (macOS system **defaults** — config, not packages).

So on mac: `setup_os/mac.sh` runs `brew bundle` (packages), and `setup_mac.sh` runs `defaults write …` (Finder/trackpad config). Two distinct jobs → two files.

## Self-guard pattern (Go-tag style)

Each `setup_os/<distro>.sh` begins with a "build tag" — it's a no-op when sourced for the wrong distro:

```bash
case "${DISTRO:-}" in
  arch|cachyos|archlabs|endeavouros|manjaro) ;;
  *)
    [[ "${BASH_SOURCE[0]:-${0}}" == "${0}" ]] && exit 0 || return 0 ;;
esac
```

The `BASH_SOURCE[0] == $0` test distinguishes "executed directly" (exit) from "sourced" (return), so each file is also runnable standalone for testing.

**Adding a new distro family** = drop a new `setup_os/<family>.sh` with its own guard. No central `case` to update — `setup_basic.sh`'s `source setup_os/*.sh` glob picks it up automatically.

## Scripts

### `setup_basic.sh`
Installs `COMMON_PACKAGES` via the distro's package manager, then `source`s every `setup_os/*.sh` so the matching distro's extras fire.

- **mac**: brew install + extras go via `setup_os/mac.sh`'s `brew bundle`
- **debian/pop/ubuntu**: apt install + eza upstream deb repo (inline)
- **arch/cachyos**: pacman install (extras + services go in `setup_os/arch.sh`)
- **fedora**: dnf install

### `setup_git.sh`
Prompts interactively for `user.name` and `user.email` if not already set in global git config. Idempotent — skips a key when already configured or when given empty input.

### `setup_os/arch.sh`
Pacman extras for the Arch family: `waybar yazi awww brightnessctl wl-clipboard powerline-fonts ncdu playerctl udisks2 blueman zed` (all in official `extra` repo). Auto-builds **yay** from AUR if no AUR helper is present (CachyOS skips this — paru ships in its `[cachyos]` repo). Installs `visual-studio-code-bin` (MS binary) via the available helper. Enables system services (NetworkManager/bluetooth/cups/fstrim/udisks2 + conditional snapper). Runs `cachyos-rate-mirrors` on CachyOS. Optional commented Hyprland GUI packages (`waypaper nwg-look nwg-displays gtk4-layer-shell`).

### `setup_os/debian.sh`
Creates the `fd` symlink, installs Zed via the official installer, and installs VS Code (MS binary) from Microsoft's apt repo.

### `setup_os/fedora.sh`
Installs Zed via the official installer and VS Code (MS binary) from Microsoft's dnf repo.

### `setup_os/mac.sh`
Runs `brew bundle --file="$DOTFILES_DIR/Brewfile"` — casks (vscode, zed, firefox, alacritty, kitty, aldente) and brews (git, zsh, stow, tmux, jq, eza, gnupg). `fnm` is intentionally not in the Brewfile — installed by `setup_programing.sh`.

### `setup_mac.sh`
macOS system **defaults** (Finder, trackpad, keyboard, screenshots). Only called on macOS. Distinct from `setup_os/mac.sh` which installs packages.

### `setup_fonts.sh`
Symlinks font files from `dotfiles/fonts/` into the OS font directory.
- **Linux**: `~/.local/share/fonts/` + `fc-cache -f`
- **macOS**: `~/Library/Fonts/`
- **Windows**: copies (symlinks not reliable for Windows font dir)

### `setup_zsh.sh [--update]`
Clones zsh plugins into `~/.config/zsh/plugins/` and tpm into `~/.config/tmux/plugins/`. Sets zsh as default shell via `chsh`.
- `--update`: `git pull --ff-only` in each plugin dir to get latest

### `setup_programing.sh`
Installs dev toolchains via **mise** (single runtime manager, replaces fnm/rustup/SDKMAN):
- **mise** manages go, java, node, rust from `~/dotfiles/mise.toml` — `mise install` provisions all
- **GitNexus**: `mise exec -- npm install -g gitnexus` (uses mise's node)
- **rtk**: paru/yay on arch, brew on mac, curl script as fallback

### `setup_skills.sh [--update]`
Inits skill submodules in `dotfiles/skills/` and symlinks each skill into agent discovery dirs (`~/.config/opencode/skills/`, `~/.claude/skills/`, `~/.codex/skills/`, `~/.agents/skills/`).
- `--update`: `git submodule update --remote --merge` first, then re-symlink

See `../skills/README.md` for adding/removing/pinning skills.

### `setup_rtk.sh`
Activates rtk for opencode by running `rtk init -g --opencode --no-patch`, which installs the opencode plugin at `~/.config/opencode/plugins/rtk.ts`. The plugin auto-rewrites bash commands to their rtk equivalents for token savings. Idempotent — skips if the plugin is already up to date. Requires the rtk binary in PATH (installed by `setup_programing.sh`).

## Flags

| Caller | Flag | Effect |
|---|---|---|
| `install.sh` | `--update` | Forward `--update` to `setup_zsh.sh` + `setup_skills.sh`; skip the slow idempotent steps (base packages, stow, mac defaults, fonts) — designed for re-syncing plugins/skills without reinstalling the world |
| `setup_zsh.sh` | `--update` | Pull latest plugin versions |
| `setup_skills.sh` | `--update` | Pull latest skill submodule commits |

## Re-running

All scripts are idempotent — safe to re-run anytime. They skip already-installed items and only create/update what's missing. `./install.sh` runs the whole thing; `./install.sh --update` is a faster re-sync that skips package managers/stow/fonts and just refreshes plugins + skills.