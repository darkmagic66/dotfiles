# Dotfiles Architecture v2 — Packages, Bootstrap, Roles (Master Spec)

Date: 2026-10-01
Status: approved by user (design presented in session), pending implementation
Supersedes: docs/plan.md (npx-skills migration — REJECTED: an external store breaks the "Git = source of truth" rule; submodules retained)
## Goal

Upgrade the restructured repo (linux/ mac/ split, Brewfile-as-mac-source) to support 4 machines per the user's new-spec.md:

```text
thinkpad     personal  linux   (CachyOS + Hyprland) — live machine, verified today
macbook-m3   company   macos   — no root; brew works (it is rootless)
macbook-m5   personal  macos   — fresh install target
windows-pc   personal  windows — sketch only in this project
```

Separation of concerns: configuration ≠ packages ≠ AI skills ≠ secrets. Git = source of truth everywhere.

## Deltas vs current state (NOT a second total restructure)

Preserved unchanged: root common stow packages (`zsh tmux nvim kitty alacritty ideavim opencode xxh`), `linux/` + `mac/` platform stow dirs, `script/` internals (`setup_zsh.sh setup_fonts.sh setup_git.sh setup_mac.sh setup_programing.sh setup_skills.sh setup_rtk.sh` incl. `setup_os/arch.sh` services/yay logic), `skills/` submodules + agent symlinks, fonts, dog/, utility/, docs/.

### G1. Package manifest — packages/manifest.yaml (single source of truth)

Format: flat top-level groups, YAML lists of plain strings only (no nesting), parsed by awk. No yq dependency.

```yaml
# Package manifest — single source of truth (4 machines, 4 package managers).
# Machine composition: common + <os> (linux|macos|windows) + optional role (role_personal|role_company)
common:
  - git
  - zsh
  - stow
  - tmux
  - jq
  - eza
  - gnupg
  - neovim
  - mise
  - atuin
  - htop
  - fd
  - fzf
  - zoxide
  - bat
  - ripgrep
  - zip
  - unzip
  - curl
  - wget
  - git-delta
  - tree-sitter-cli
  - lazygit

linux:     # pacman; arch-family only
  - kitty
  - waybar
  - yazi
  - awww
  - brightnessctl
  - wl-clipboard
  - powerline-fonts
  - ncdu
  - playerctl
  - udisks2
  - blueman
  - zed      # N1: confirm exact membership against script/setup_os/arch.sh before migrating

macos_casks:    # brew --cask
  - alacritty
  - kitty
  - firefox
  - visual-studio-code
  - zed

macos_extra:    # brew formulas beyond common
  - xxh
  - tldr
  - asciinema

role_personal:  # aldente moved out of macos_casks: personal only
  - aldente

role_company: []  # company mac = common + macos only, no personal extras

windows:        # winget ids — sketch
  - Git.Git
  - junegunn.fzf
  - BurntSushi.ripgrep.MSVC
  - sharkdp.fd
  - Neovim.Neovim
```

Parser contract (`bootstrap/lib/manifest.sh`):
- `MANIFEST="${DOTFILES_DIR}/packages/manifest.yaml"`
- `manifest_packages <group>` prints names, space-separated; fails loudly on missing group or missing file.
- awk-based. No external deps beyond POSIX tools.
- Truth mapping (verified against today's lists): old `COMMON_PACKAGES` ≈ `common`; old `install_mac` extras (tldr, asciinema via old brew block) ≈ `macos_extra` or already in `common`; old arch.sh extras ≈ `linux`; old casks ≈ `macos_casks`; aldente moves to `role_personal`.
- `COMMON_PACKAGES` array: DELETED from setup_basic.sh (replaced by manifest reads).
- `Brewfile`: DELETED from repo.
- kitty: pacman formula but brew CASK — lives in `linux` (pacman) and `macos_casks` (brew), NOT in `common`. alacritty: same treatment (pacman formula, brew cask today).

N1 — resolve during implementation by reading script/setup_os/arch.sh: confirm exact zed/xxh/visual-studio-code handling (verify package names and repo sources in the file; don't rely on this doc's memory).

### G2. Package adapters — replaces per-OS arrays

`bootstrap/lib/adapters/<os>.sh`, self-guarded (same pattern as today's setup_os):

- `pacman.sh`: manifest `common` + `linux` via pacman (requires sudo — thinkpad user has root). Keeps arch-only steps: yay auto-build if no helper, AUR/`vscode-bin` handling, service enable, cachyos-rate-mirrors. No hostname hardcodes.
- `brew.sh`: manifest `common` formulas (macOS ships `/usr/bin/curl`; the brew adapter skips common names unavailable as brew formulas — the SKIP list is explicit in the adapter, not derived) + `macos_extra` brews + `macos_casks` casks + `role_personal` casks when ROLE=personal.
- `debian.sh`: apt for `common` minus the formula-specific package (eza needs upstream deb repo — PRESERVE today's keyring logic), fd-find → fd symlink (preserved), zed installer + vscode MS apt repo (preserved), plus `tldr asciinema python3 build-essential` (today's behavior).
- `fedora.sh`: dnf equivalent (preserved zed installer + vscode MS dnf repo).
- `win.sh`: SKETCH ONLY — resolves `windows` group, prints the winget commands it WOULD run, exits 0 without executing (no windows machine reachable yet; documented limitation).

`script/setup_basic.sh` shrinks: delete COMMON_PACKAGES array + all four inline install_* OS branches; the file becomes `source` → dispatcher chain calling the matching adapter, preserving the `setup_os/*.sh`-glob idea in name but pointed at `bootstrap/lib/adapters/*.sh`.

### G3. Machine profiles + roles

One central file `bootstrap/lib/hosts.sh`:

```bash
declare -A HOST_ROLE=(
  ["<thinkpad hostname>"]=personal
  ["<macbook-m3 hostname>"]=company
  ["<macbook-m5 hostname>"]=personal
  ["<windows hostname>"]=personal
)
```

- Hostname known: role = `HOST_ROLE[<hostname>]`.
- Hostname unknown/untracked: interactive `personal|company` prompt ONCE, answer saved to `~/.config/dotfiles/role` (an untracked machine-local file). If that file exists, it takes precedence over new prompts and unknown hosts. Git stays clean — the file is machine-local state, documented in the README secrets section.
- Hostname table placeholders are filled during implementation; real macbook values get added on the M5/M3 first install (single edit point).

`roles/` stow packages:
- `roles/personal/.gitkeep`
- `roles/company/.gitkeep`
- Stow integration in the config step: `stow -t "$HOME" -d roles personal` when ROLE=personal, `company` when ROLE=company. Same `-t "$HOME"` semantics as other groups.
- Package adapter also consults ROLE: brew installs `role_personal` only when personal; pacman same idea (now nothing personal on arch → group empty by default).

### G4. Bootstrap entry + subcommands

New executable `bootstrap` at repo root (no file extension):

```bash
./bootstrap packages   # manifest → adapter dispatch (idempotent)
./bootstrap config     # stow everything (per ROLE + OS)
./bootstrap ai         # setup_skills.sh + setup_rtk.sh only
./bootstrap            # full flow: packages → config → ai + fonts + zsh + programming + mac defaults
./bootstrap --update   # full flow mode --update (fast re-sync)
```

Move these invocation steps verbatim from install.sh into `bootstrap/lib/full.sh` (one file, reuses reviewed logic): internet check, OS detect, chmod, setup_git.sh, setup_fonts.sh, setup_zsh.sh, setup_programing.sh, setup_rtk.sh, skills, mac defaults — order unchanged.

After migration:
- install.sh = 3-line shim: `exec "$(dirname "$0")/bootstrap" "$@"` (keeps MacBook-runbook muscle memory).
- script/setup_basic.sh: only `source bootstrap/lib/{common,manifest,hosts}.sh` once + adapter dispatch (job from today's setup_basic.sh).
- script/setup_os/*.sh deleted.

### G5. AI skills (sub-project B)

- 4 submodules STAY: superpowers, mattpocock-skills, caveman, skill-tissue-skills.
- npx skills: REJECTED (breaks the "Git = source of truth" rule). Personal skills (the repo's own future skills) live in plain dirs under `skills/personal/` when they appear; external skills stay submodules under `skills/`. The existing symlink exposure (opencode/claude/codex/.agents) already gives cross-agent access.
- New CLI: `bootstrap ai list | update | status` — thin bash wrapper over `git submodule ...`; prints personal/external split view:
  ```text
  Personal:   (none yet)
  External:
    ✓ superpowers        (pinned)
    ✓ mattpocock-skills  (pinned)
    ...
  ```
  Where `update` = `git submodule update --remote --merge`, `status` = `git submodule status`. No Makefile, no npm tooling.
- setup_skills.sh internals UNCHANGED; `bootstrap ai` subcommands wrap it.
- `docs/plan.md` DELETED (its premise rejected; history preserved in git).

### G6. Windows + secrets + docs

- Windows: manifest `windows` group + `bootstrap/lib/adapters/win.sh` sketch (prints, doesn't run). Real windows support becomes a separate later sub-project.
- Secrets: rule already followed (audit found zero tracked secrets). README gains a short section: tokens/keys/passwords NEVER in Git; machine-local secrets live in untracked files (pattern: `~/.config/zsh/.zshrc.local`). Zero code.
- Docs sync: README (layout + manifest + bootstrap subcommands), `script/README.md` (package lists now in manifest; setup_* descriptions updated), `docs/install.flow.mmd` (new bootstrap flow).
- Verification (this machine = thinkpad, CachyOS): manifest parse, adapter dry-runs, idempotent `bootstrap --update` and full `./bootstrap` on already-configured machine. Real mac test = documented runbook, not runnable here (known gap).

## Acceptance Criteria

- [ ] Zero per-OS package arrays left in `script/` — only manifest.
- [ ] Brewfile gone; brew installs/casks come from manifest.
- [ ] roles/personal + roles/company exist; host → role resolution works on thinkpad today and provides the M5/M3 skip-until-real-hostname path.
- [ ] bootstrap subcommands run independently; full flow idempotent on thinkpad.
- [ ] skills CLI list/update/status works; npx line dropped; plan.md gone.
- [ ] README / script/README / flow diagram describe manifest + bootstrap; secrets rule documented.
- [ ] M5 runbook in docs: clone → `./bootstrap` step-by-step, and what to fill in hosts.sh afterwards.

## ARCH — estimate of working files

```text
bootstrap                  (new exec)
bootstrap/lib/common.sh
bootstrap/lib/manifest.sh
bootstrap/lib/hosts.sh
bootstrap/lib/adapters/pacman.sh
bootstrap/lib/adapters/brew.sh
bootstrap/lib/adapters/debian.sh
bootstrap/lib/adapters/fedora.sh
bootstrap/lib/adapters/win.sh       (sketch)
bootstrap/lib/{packages,config,ai}-subcommand impls
packages/manifest.yaml              (new)
roles/personal/.gitkeep roles/company/.gitkeep   (new)
install.sh                           (→ 3-line shim)
script/setup_basic.sh                (→ thin dispatcher)
script/setup_os/                     (deleted)
Brewfile docs/plan.md                (deleted)
```
