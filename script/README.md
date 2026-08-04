# Scripts

Called by `../install.sh` in order. Each script is standalone and idempotent (safe to re-run).

## Execution order

```
install.sh
├── 1. setup_basic.sh     # install base packages (tmux, zsh, nvim, stow, eza, etc.) + AUR helper on arch
├── 2. stow               # symlink dotfiles into $HOME (alacritty, ideavim, kitty, nvim, opencode, tmux, zsh)
├── 3. setup_mac.sh       # macOS-only: Finder/trackpad/keyboard defaults
├── 4. setup_fonts.sh     # symlink fonts from dotfiles/fonts/ into OS font dir
├── 5. setup_zsh.sh       # clone zsh plugins (p10k, autosuggestions, etc.) + tpm + chsh -s zsh
├── 6. setup_programing.sh # install rustup, SDKMAN, GitNexus, rtk (OS-aware)
└── 7. setup_skills.sh    # init skill submodules + symlink skills into agent dirs
```

## Scripts

### `setup_basic.sh [distro]`
Installs base packages via the distro's package manager. Detects distro from `/etc/os-release` or arg.

- **mac**: brew install + `brew bundle` from Brewfile
- **debian/pop/ubuntu**: apt install (eza from upstream deb repo, fd is `fd-find` with symlink)
- **arch/cachyos**: pacman install + paru/yay for AUR packages (fnm). Auto-installs paru if no AUR helper found.
- **fedora**: dnf install

### `setup_fonts.sh [os_type]`
Symlinks font files from `dotfiles/fonts/` into the OS font directory.
- **Linux**: `~/.local/share/fonts/` + `fc-cache -f`
- **macOS**: `~/Library/Fonts/`
- **Windows**: `%LOCALAPPDATA%\Microsoft\Windows\Fonts\` (copies, not symlinks — Windows font dir doesn't support symlinks reliably)

### `setup_zsh.sh [--update]`
Clones zsh plugins into `~/.config/zsh/plugins/` and tpm into `~/.config/tmux/plugins/`.
Sets zsh as default shell via `chsh -s $(which zsh)`.

- `--update`: `git pull --ff-only` in each plugin dir to get latest

### `setup_programing.sh`
Installs dev toolchains (OS-aware):
- **rustup**: pacman on arch, curl script on mac/debian
- **SDKMAN**: curl script on all OSes
- **GitNexus**: `npm install -g gitnexus`
- **rtk**: paru/yay on arch, brew on mac, curl script as fallback

### `setup_skills.sh [--update]`
Inits skill submodules in `dotfiles/skills/` and symlinks each skill into agent discovery dirs:
`~/.config/opencode/skills/`, `~/.claude/skills/`, `~/.codex/skills/`, `~/.agents/skills/`.

- `--update`: `git submodule update --remote --merge` first, then re-symlink

See `../skills/README.md` for adding/removing/pinning skills.

### `setup_mac.sh`
macOS system defaults (Finder, trackpad, keyboard, screenshots). Only called on macOS.

## Flags

| Script | Flag | Effect |
|---|---|---|
| `setup_zsh.sh` | `--update` | Pull latest plugin versions |
| `setup_skills.sh` | `--update` | Pull latest skill submodule commits |

## Re-running

All scripts are idempotent — safe to re-run anytime. They skip already-installed items and only create/update what's missing.