# Handoff: Pop!_OS → CachyOS + Hyprland migration

## Current state
**Part A (config rewrite + skills consolidation + script fixes) is COMPLETE and pushed. Part B (disk wipe + reinstall) is PAUSED, awaiting user authorization.**

User said "save this session i will do sth first" — likely backing up SSH keys / personal data before authorizing the irreversible disk wipe.

Three commits pushed to `git@github.com:darkmagic66/dotfiles.git` branch `main`:
- `634f463` config rewrite for arch/cachyos migration
- `9616d5f` consolidate skills into ~/dotfiles/skills/ with submodule + symlink pattern
- `04e9c66` fix scripts: critical bugs + quality improvements

## User profile (key facts)
- GitHub username: `darkmagic66`
- SSH key on Pop!_OS: `~/.ssh/darkmagic66-github` (ed25519, 904B .pub)
- SSH host alias: `github.com-pongsatorn66` (User darkmagic66, IdentityFile ~/.ssh/darkmagic66-github)
- Git config: name=pongsatorn, email=owlee.666666@gmail.com
- Distro: Pop!_OS 22.04 (ID=pop, ID_LIKE=ubuntu debian)
- Kernel: 7.0.11-76070011-generic
- Hardware: AMD Ryzen 7 PRO 5850U (Zen 3, 16 threads) + AMD Cezanne iGPU (`amdgpu`) — no NVIDIA, Hyprland works natively
- RAM: 12GB
- Disk: 477GB NVMe `nvme0n1` (Micron MTFDHBA512TDV)
  - p1: 1G vfat EFI `/boot/efi`
  - p2: 152G ext4 `/`
  - p3: 295G ext4 `/home` (180G used, 96G free)
  - p4: 8G swap (LUKS)
  - p5: 20G ext4 recovery `/recovery`
- ~~External backup drive~~ (none available — user chose "dotfiles only")
- Multi-machine user: Linux + macOS + Windows

## What's done in Part A (all pushed to GitHub)

### Config rewrites (commit 634f463)
- `zsh/.zshrc` — `typeset -U path` idempotent PATH, `exa`→`eza`, `zsh-nvm`→`fnm`, conditional SDKMAN/bun sources, fpath before compinit, machine-local override hook (`~/.config/zsh/.zshrc.local`)
- `tmux/.config/tmux/tmux.conf` — `tmux-256color` + truecolor override, reload bind, dead catppuccin block removed
- `alacritty/.config/alacritty/alacritty.toml` — dropped legacy `.yml`, `save_to_clipboard`, font → JetBrainsMono
- `kitty/.config/kitty/kitty.conf` — NEW (Hyprland default terminal), gruvbox, wayland-native
- `nvim/.config/nvim/lua/configs/{conform,lint}.lua.bak` — deleted. NvChad kept intact (user explicitly liked it)
- Local NvChad backup at `~/dotfiles-nvchad-backup/` (NOT pushed)
- `fonts/` — 229MB → 46MB, removed 0-byte placeholders + 3 duplicate Nerd Fonts (kept JetBrainsMono + Thai fonts)

### Skills consolidation (commit 9616d5f)
- Created `~/dotfiles/skills/` as single source of truth
- 4 submodules:
  - `skills/superpowers` (obra/superpowers, pinned to tag `v6.2.0`)
  - `skills/mattpocock-skills` (mattpocock/skills)
  - `skills/caveman` (juliusbrussee/caveman)
  - `skills/skill-tissue-skills` (skill-tissue/skills — backseat, cvmn)
- 1 plain folder: `skills/karpathy-guidelines/SKILL.md` (no submodule for one file)
- Wrote `script/setup_skills.sh` — cross-OS (Linux/macOS/Windows) installer that inits submodules and symlinks 37 skills into 4 agent dirs (`~/.config/opencode/skills/`, `~/.claude/skills/`, `~/.codex/skills/`, `~/.agents/skills/`). Skill selection configurable via arrays at top of script. Supports `--update` flag.
- Wrote `skills/README.md` — docs for adding/updating/pinning skills, adding new agents, cross-OS notes, rtk find caveats
- Deleted: `ai-env/` (broken submodules + gemini config), `.gemini/` (no gemini), obsolete scripts (`setup_ai.sh`, `install_superpowers.sh`, `add_skill.sh`, `update_karpathy_skill.sh`), `opencode/.claude/` + `opencode/.copilot/` + `opencode/.config/opencode/skills/` (stow-based skill sharing — replaced by setup_skills.sh)
- Removed `superpowers` plugin entry from `opencode/.config/opencode/opencode.jsonc` (loaded via symlinks now)
- 7 stale submodule entries removed from `.gitmodules`

### Script bug fixes (commit 04e9c66)
- `setup_skills.sh`: `rtk git` → `git` (rtk not installed on fresh machine — chicken-and-egg)
- `setup_basic.sh`: `eza` moved to OS-specific (not in Ubuntu 22.04 apt). Debian: installs from upstream deb repo. Arch: pacman. Mac: brew. Auto-creates `fd` → `fdfind` symlink on debian.
- `setup_basic.sh`: `stow` + `zsh` added to COMMON_PACKAGES
- `setup_basic.sh`: auto-installs `paru` AUR helper on arch if not present
- `setup_zsh.sh`: removed dead `zsh-nvm` plugin (replaced by fnm). Added `--update` flag + `chsh -s $(which zsh)`
- `setup_fonts.sh`: `cp` → symlinks + Windows support
- `install.sh`: `ping` → `curl -sSf github.com`, one-liner `chmod +x script/*.sh`, next-steps hints
- `setup_mac.sh`: expanded from 2 lines to 20+ useful macOS defaults
- `set -euo pipefail` added to all scripts
- `script/README.md` documenting execution order + each script's purpose

## What's left

### Part B — disk wipe + CachyOS install (LOCKED plan, awaiting user "go")

Cannot execute until user:
1. Backs up SSH keys (`~/.ssh/darkmagic66-github*`, `~/.ssh/gitlab_linux`, `~/.ssh/config`) — these won't survive wipe
2. Backs up anything else they care about (browser passwords, app configs)
3. Says "go" to authorize the irreversible wipe

### Part B plan

#### B.1 Create bootable USB
- Download CachyOS Hyprland edition ISO (~3GB) from `cachyos.org`
- Verify SHA256
- Flash: `sudo dd if=cachyos-hyprland.iso of=/dev/sdX bs=4M status=progress && sync`
  - or use Ventoy
- Boot from USB (F12 on Lenovo laptop)

#### B.2 Install CachyOS (ERASE entire disk)
- Calamares → Erase disk
- Filesystem: BTRFS (subvols `@`, `@home` for snapper)
- Kernel: `linux-cachyos` (sched-ext optimized for Zen 3)
- Bootloader: `systemd-boot` (matches Pop!_OS muscle memory)
- Drop disk swap → use zram only (12GB RAM plenty)
- Optional: LUKS on `/` only (keep EFI unencrypted for systemd-boot)
- Reboot

#### B.3 First boot essentials
```bash
sudo pacman -Syu
sudo pacman -S --needed base-devel git curl wget stow tmux zsh neovim \
    eza ripgrep fd bat fzf jq htop git-delta zoxide starship \
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-thai powerline-fonts \
    wl-clipboard pipewire pipewire-pulse pipewire-alsa wireplumber \
    brightnessctl playerctl hyprpaper hypridle hyprlock swww \
    networkmanager bluez bluez-utils cups
sudo systemctl enable --now NetworkManager bluetooth cups fstrim.timer
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
sudo cachyos-rate-mirrors
# Chaotic-AUR is bundled with CachyOS
```

#### B.4 Hyprland config (accept CachyOS defaults + small tweaks)
- CachyOS Hyprland ISO ships working `~/.config/hypr/` — keep defaults
- Optional additions to `~/.config/hypr/hyprland.conf`:
  - `monitor=,preferred,auto,1`
  - `env = XDG_SESSION_TYPE,wayland`
  - `env = XDG_CURRENT_DESKTOP,Hyprland`
  - `env = QT_QPA_PLATFORMTHEME,qt5ct`
  - No NVIDIA-specific lines needed (AMD iGPU)

#### B.5 Restore dotfiles
```bash
# SSH key must be regenerated OR restored from backup BEFORE this step
git clone --recurse-submodules git@github.com:darkmagic66/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

`install.sh` will:
1. Install base packages via `setup_basic.sh` (detects cachyos as arch, installs pacman packages + paru + AUR fnm)
2. Stow dotfiles (alacritty, ideavim, kitty, nvim, opencode, tmux, zsh)
3. Run `setup_fonts.sh`, `setup_zsh.sh` (with chsh + plugin clones), `setup_programing.sh` (rustup, SDKMAN, gitnexus, rtk), `setup_skills.sh` (init submodules + symlink 37 skills to 4 agent dirs)

#### B.6 Verify post-migration
- Hyprland renders, terminal (kitty default) opens
- zsh + p10k loads, `eza`/`fnm` work
- nvim opens, `:checkhealth` green, `:Mason` shows LSPs installed
- tmux works, `prefix + I` installs TPM plugins
- Audio: `pactl info` → pipewire
- Network: `nmcli device status`
- Bluetooth: `bluetoothctl power on`
- Lid close → suspend via `hypridle`
- Skills visible in opencode (37 skills via `/skills` or skill tool)

#### B.7 (Optional, deferred) chezmoi migration
After running CachyOS for a few weeks:
```bash
paru -S chezmoi
chezmoi init
cd ~/dotfiles && chezmoi add ~/.zshrc ~/.tmux.conf ~/.config/alacritty ~/.config/nvim ~/.config/hypr ~/.config/kitty
# Convert hardcoded paths to chezmoi templates ({{ .chezmoi.hostname }}, etc.)
# Push to new chezmoi repo or convert existing dotfiles repo
```

## Decisions locked (do not re-ask)
- Keep NvChad (do NOT rewrite to kickstart.nvim or LazyVim)
- Tmux theme: keep current red/yellow-on-black
- Default terminal on Hyprland: **kitty** (alacritty as fallback)
- SDKMAN: keep on all OSes (made conditional, not removed)
- rtk: keep (user finds it token-efficient), with `/usr/bin/find` workaround for compound predicates
- GitNexus: keep, moved to `setup_programing.sh` (dev tool, not a skill)
- Dotfiles repo: PRIVATE GitHub repo at `git@github.com:darkmagic66/dotfiles.git` (already exists, user's own)
- Skills via submodules + symlinks (NOT npx skills, NOT stow-based)
- Stop and ask user before starting Part B

## Suggested skills to load when resuming
- `using-superpowers` (always — orientation)
- `executing-plans` (Part B is an implementation plan with review checkpoints)
- `verification-before-completion` (before claiming "CachyOS install done")
- `systematic-debugging` (if any of B.6 fails — Hyprland issues etc.)

## How to resume this work
Invoke the `handoff` skill's output (this document) as context. The plan is complete and ready to execute — wait for user to say "go" / authorize Part B (the disk wipe).

**Do NOT begin any of Part B without explicit user authorization** — it is irreversible (wipes 477GB NVMe). User has not yet backed up SSH keys.

## Quick references
- Dotfiles repo: `git@github.com:darkmagic66/dotfiles.git`
- Commit history: `634f463` → `9616d5f` → `04e9c66` (all on main)
- NvChad local backup: `~/dotfiles-nvchad-backup/` (not pushed, will be lost on wipe — but NvChad config is in the repo anyway)
- Skills README: `~/dotfiles/skills/README.md`
- Scripts README: `~/dotfiles/script/README.md`