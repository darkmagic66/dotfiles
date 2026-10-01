# dotfiles

Personal dotfiles for **CachyOS / Arch + Hyprland**, **macOS**, with fallbacks for Debian and Fedora.

## Install

```bash
git clone --recursive https://github.com/<you>/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`./install.sh --update` does a fast re-sync: forwards `--update` to `setup_zsh.sh` + `setup_skills.sh` (refreshes plugins and skill submodules) but skips the slow package-manager / stow / fonts steps.

## What gets installed

### Packages (per OS)
- **All OSes (COMMON)**: tmux, htop, fd, fzf, bat, ripgrep, jq, neovim, git, stow, zsh, zip, unzip, curl, wget, git-delta, zoxide, eza, kitty
- **Arch family**: waybar, yazi, awww, brightnessctl, wl-clipboard, powerline-fonts, ncdu, playerctl, udisks2, blueman, zed, xxh (AUR) + services (NetworkManager/bluetooth/cups/fstrim/udisks2)
- **macOS**: the Brewfile (aldente, alacritty, kitty, firefox, vscode, zed, xxh)
- **Debian/Fedora**: zed installer + Microsoft's apt/dnf repo for vscode

### Editors
- **nvim** (NvChad on lazy.nvim)
- **zed**
- **vscode** (Visual Studio Code)

### Other setup
- **Stow** symlinks common configs into $HOME on every platform (`zsh tmux nvim kitty alacritty ideavim opencode xxh`), plus Linux-only packages (`hypr waybar gtk qt fontconfig`) via `stow -d linux` — skipped on macOS.
- **zsh** (vim style): plugins (powerlevel10k, autosuggestions, completions, syntax-highlighting, vi-mode) + tmux plugin manager + `chsh -s zsh`
- **xxh**: portable shell over ssh — `~/.config/xxh/config.xxhc` pins `+s zsh`, powerlevel10k + zoxide plugins; use `xxh <host>` instead of `ssh <host>` (target hosts: Linux x86_64)
- **Fonts** from `fonts/` symlinked into the OS font directory
- **macOS defaults** (Finder/trackpad/keyboard/screenshots) on mac only
- Programming toolchains via `setup_programing.sh`: mise (go/java/node/rust), GitNexus, rtk
- Agent skills via `setup_skills.sh`: skills submodules symlinked into `~/.config/opencode/skills/`, `~/.claude/skills/`, `~/.codex/skills/`, `~/.agents/skills/`

## Layout

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

See [`script/README.md`](script/README.md) for the detailed execution order and the `setup_os/` self-guard pattern.

## Info
* editor: NVChad (on lazy.nvim) + zed + vscode
* shell: zsh — vim style
* shell styling: manual (powerlevel10k)
* terminal emulator: alacritty, kitty
* terminal multiplexer: tmux
* dotfile manager: stow