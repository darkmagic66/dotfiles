# Handoff: Pop!_OS → CachyOS + Hyprland migration

## Current state
**Backup COMPLETE and verified. Disk wipe + CachyOS install is the next step.**

Everything irreplaceable is on flash drive `CCCOMA_X64F` (116G exfat, `/dev/sda1`, mounted at `/media/pongsatorn66/CCCOMA_X64F/`).

### What's on the flash drive (verified)
| Item | Location | Size |
|------|----------|------|
| Documents | `CCCOMA_X64F/Document/` | 1.3G |
| Pictures | `CCCOMA_X64F/picture/` | 224M |
| Videos | `CCCOMA_X64F/vdo/` | 15G |
| coding (leetcode etc) | `CCCOMA_X64F/coding/` | 1.1G |
| proj (anime-list, blog, lab, ...) | `CCCOMA_X64F/proj/` | 2.5G |
| blog | `CCCOMA_X64F/blog/` | 6.7M |
| Browser profiles (Chrome + Brave + Firefox) | `CCCOMA_X64F/browser-profiles/` | ~7G |
| SSH keys + gitconfig tarball | `CCCOMA_X64F/migration-backup.tar.gz` | 5.9K |

### Not backed up (intentional — user confirmed these are not needed)
- `~/note/`, `~/openVPN/`, `~/Music/`, `~/quick_blog/`, `~/temp/`, `~/script/`, `~/Desktop/`, `~/Downloads/`

### Dotfiles repo status
- `git@github.com:darkmagic66/dotfiles.git` branch `main`, HEAD `8ff5786` (pushed)
- GitHub SSH key (`~/.ssh/darkmagic66-github`) works: `ssh -T git@github.com` → "Hi darkmagic66!"
- Everything needed to bootstrap is in the repo

### tarball contents (`migration-backup.tar.gz`)
```
.ssh/config
.ssh/gitlab_linux (+ .pub)
.ssh/podman-machine-default (+ .pub)
.ssh/darkmagic66-github (+ .pub)
ssh-key/gitlab_linux (+ .pub)
.gitconfig
```

## User profile (key facts)
- GitHub username: `darkmagic66`, git name=pongsatorn, email=owlee.666666@gmail.com
- SSH host alias: `github.com-pongsatorn66` (User darkmagic66, IdentityFile ~/.ssh/darkmagic66-github)
- Hardware: AMD Ryzen 7 PRO 5850U (Zen 3, 16 threads) + AMD Cezanne iGPU (`amdgpu`) — no NVIDIA, Hyprland works natively
- RAM: 12GB
- Disk: 477GB NVMe `nvme0n1`
- Multi-machine user: Linux + macOS + Windows

---

## WHAT TO DO NEXT (post-wipe, on CachyOS + Hyprland)

### Step 1 — Install CachyOS Hyprland edition
- Download CachyOS Hyprland ISO from `cachyos.org`
- Verify SHA256
- Flash to USB: `sudo dd if=cachyos-hyprland.iso of=/dev/sdX bs=4M status=progress && sync` (or use Ventoy)
- Boot from USB
- Calamares installer:
  - Erase entire disk
  - Filesystem: **BTRFS** (subvols `@`, `@home` for snapper)
  - Kernel: `linux-cachyos` (sched-ext optimized for Zen 3)
  - Bootloader: **systemd-boot** (matches Pop!_OS muscle memory)
  - Drop disk swap → use zram only (12GB RAM plenty)
  - Optional: LUKS on `/` only (keep EFI unencrypted for systemd-boot)
- Reboot

### Step 2 — First boot essentials
```bash
sudo pacman -Syu
sudo pacman -S --needed base-devel git curl wget stow tmux zsh neovim \
    eza ripgrep fd bat fzf jq htop git-delta zoxide starship \
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-thai powerline-fonts \
    wl-clipboard pipewire pipewire-pulse pipewire-pipewire-alsa wireplumber \
    brightnessctl playerctl hyprpaper hypridle hyprlock swww \
    networkmanager bluez bluez-utils cups
sudo systemctl enable --now NetworkManager bluetooth cups fstrim.timer
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
sudo cachyos-rate-mirrors
```
CachyOS bundles Chaotic-AUR so most AUR packages install via pacman.

### Step 3 — Restore SSH keys from flash drive FIRST
The dotfiles clone needs the github key. Plug in `CCCOMA_X64F` flash drive.
```bash
# Mount the flash drive (CachyOS usually auto-mounts under /media or /run/media)
# Restore SSH dir from tarball
mkdir -p ~/.ssh
cd ~ && tar xzf /media/$USER/CCCOMA_X64F/migration-backup.tar.gz --strip-components=2
# ^^ extracts into ~/.ssh/ + ~/.ssh/ssh-key/ + ~/.gitconfig
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*_linux ~/.ssh/darkmagic66-github ~/.ssh/podman-machine-default
chmod 644 ~/.ssh/*.pub ~/.ssh/config
```

### Step 4 — Verify SSH to GitHub
```bash
ssh -T git@github.com
# Expect: "Hi darkmagic66! You've successfully authenticated, but GitHub does not provide shell access."
```
If it fails, check `~/.ssh/config` has the `github.com-pongsatorn66` host alias pointing at `~/.ssh/darkmagic66-github`.

### Step 5 — Clone dotfiles + run installer
```bash
git clone --recurse-submodules git@github.com:darkmagic66/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

`install.sh` will:
1. Detect CachyOS as arch → `setup_basic.sh` installs pacman packages + `paru` AUR helper + `fnm`
2. Stow dotfiles: `stow alacritty ideavim kitty nvim opencode tmux zsh`
3. `setup_fonts.sh` symlinks JetBrainsMono + Thai fonts
4. `setup_zsh.sh` clones p10k + zsh plugins + runs `chsh -s $(which zsh)`
5. `setup_programing.sh` installs rustup, SDKMAN, gitnexus, rtk
6. `setup_skills.sh` inits submodules + symlinks 37 skills into 4 agent dirs

### Step 6 — Hyprland config
CachyOS Hyprland ISO ships working `~/.config/hypr/` — keep defaults first.
Optional tweaks to `~/.config/hypr/hyprland.conf`:
```
monitor=,preferred,auto,1
env = XDG_SESSION_TYPE,wayland
env = XDG_CURRENT_DESKTOP,Hyprland
env = QT_QPA_PLATFORMTHEME,qt5ct
```
No NVIDIA-specific lines needed (AMD iGPU).

### Step 7 — Restore personal data from flash drive
```bash
cp -r /media/$USER/CCCOMA_X64F/Document/* ~/Documents/
cp -r /media/$USER/CCCOMA_X64F/picture/* ~/Pictures/
cp -r /media/$USER/CCCOMA_X64F/vdo/* ~/Videos/
cp -r /media/$USER/CCCOMA_X64F/coding ~/coding
cp -r /media/$USER/CCCOMA_X64F/proj ~/proj
cp -r /media/$USER/CCCOMA_X64F/blog ~/blog
```

### Step 8 — Restore browser profiles (BEFORE launching browsers)
```bash
mkdir -p ~/.config ~/.mozilla
cp -r /media/$USER/CCCOMA_X64F/browser-profiles/google-chrome ~/.config/
cp -r /media/$USER/CCCOMA_X64F/browser-profiles/BraveSoftware ~/.config/
cp -r /media/$USER/CCCOMA_X64F/browser-profiles/.mozilla ~/
```
**Password caveat**: if passwords were protected by the old OS keyring they won't decrypt. If you exported passwords to CSV from the old system, import them via browser settings GUI instead.

### Step 9 — Verify everything
- [ ] Hyprland renders, kitty (default terminal) opens
- [ ] zsh + p10k loads, `eza`/`fnm` work, `exec $SHELL` to reload
- [ ] nvim opens, `:checkhealth` green, `:Mason` shows LSPs
- [ ] tmux works, `prefix + I` installs TPM plugins
- [ ] Audio: `pactl info` → pipewire
- [ ] Network: `nmcli device status`
- [ ] Bluetooth: `bluetoothctl power on`
- [ ] Lid close → suspend via `hypridle`
- [ ] Skills visible in opencode (37 skills via skill tool)

### Step 10 — Commit any new tweaks back to the repo
```bash
cd ~/dotfiles
git add -A
git commit -m "cachyos: post-install tweaks"
git push origin main
```

---

## Decisions locked (do not re-ask)
- Keep NvChad (do NOT rewrite to kickstart.nvim or LazyVim)
- Tmux theme: keep current red/yellow-on-black
- Default terminal on Hyprland: **kitty** (alacritty as fallback)
- SDKMAN: keep on all OSes (made conditional, not removed)
- rtk: keep (user finds it token-efficient), with `/usr/bin/find` workaround for compound predicates
- GitNexus: keep, moved to `setup_programing.sh` (dev tool, not a skill)
- Dotfiles repo: PRIVATE GitHub repo at `git@github.com:darkmagic66/dotfiles.git`
- Skills via submodules + symlinks (NOT npx skills, NOT stow-based)

## Quick references
- Dotfiles repo: `git@github.com:darkmagic66/dotfiles.git`
- Latest commit: `8ff5786` (main, pushed)
- Skills README: `~/dotfiles/skills/README.md`
- Scripts README: `~/dotfiles/script/README.md`
- Backup checklist: `~/dotfiles/BACKUP-CHECKLIST.md`