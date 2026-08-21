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
- **Arch family**: waybar, yazi, awww, brightnessctl, wl-clipboard, powerline-fonts, ncdu, playerctl, udisks2, blueman, zed + services (NetworkManager/bluetooth/cups/fstrim/udisks2)
- **macOS**: the Brewfile (aldente, alacritty, kitty, firefox, vscode, zed)
- **Debian/Fedora**: zed installer + Microsoft's apt/dnf repo for vscode

### Editors
- **nvim** (NvChad on lazy.nvim)
- **zed**
- **vscode** (Visual Studio Code)

### Other setup
- **Stow** symlinks the config dirs into `$HOME`: `alacritty hypr ideavim kitty nvim opencode tmux waybar zsh`
- **zsh** (vim style): plugins (powerlevel10k, autosuggestions, completions, syntax-highlighting, vi-mode) + tmux plugin manager + `chsh -s zsh`
- **Fonts** from `fonts/` symlinked into the OS font directory
- **macOS defaults** (Finder/trackpad/keyboard/screenshots) on mac only
- Programming toolchains via `setup_programing.sh`: mise (go/java/node/rust), GitNexus, rtk
- Agent skills via `setup_skills.sh`: skills submodules symlinked into `~/.config/opencode/skills/`, `~/.claude/skills/`, `~/.codex/skills/`, `~/.agents/skills/`

## Layout

```
~/dotfiles/
├── install.sh            # entry point
├── script/
│   ├── setup_basic.sh     # COMMON packages + sources script/setup_os/*.sh
│   ├── setup_os/          # distro-specific extras (one file per family, self-guarded)
│   │   ├── arch.sh        #   pacman extras + yay auto-build + vscode-bin (AUR) + services
│   │   ├── mac.sh         #   brew bundle
│   │   ├── debian.sh      #   fd symlink + zed installer + vscode MS apt repo
│   │   └── fedora.sh      #   zed installer + vscode MS dnf repo
│   ├── setup_programing.sh # mise (go/java/node/rust), GitNexus, rtk
│   ├── setup_zsh.sh        # zsh plugins + tpm + chsh
│   ├── setup_fonts.sh     # symlink fonts
│   ├── setup_skills.sh    # skill submodules + symlinks
│   ├── setup_mac.sh       # macOS system defaults (Finder/trackpad — config, not packages)
│   └── README.md          # detailed script documentation
├── skills/                # agent skill submodules (see skills/README.md)
├── Brewfile               # macOS homebrew bundle
└── fonts/                 # symlinked to OS font dir
```

See [`script/README.md`](script/README.md) for the detailed execution order and the `setup_os/` self-guard pattern.

## Info
* editor: NVChad (on lazy.nvim) + zed + vscode
* shell: zsh — vim style
* shell styling: manual (powerlevel10k)
* terminal emulator: alacritty, kitty
* terminal multiplexer: tmux
* dotfile manager: stow