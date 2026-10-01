# Dotfiles Architecture v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development (or executing-plans). Checkbox steps track progress.

**Goal:** Single package manifest (`packages/manifest.yaml`), bash adapters per package manager, hostname→role profiles, `bootstrap` entry with subcommands, AI-skills CLI — replacing COMMON_PACKAGES/Brewfile/setup_os duplication.

**Architecture:** New `bootstrap/` layer (lib + adapters) reads manifest; old `script/setup_*` files keep their one-job scripts but lose all package arrays; `install.sh` becomes a shim. Spec: `docs/superpowers/specs/2026-10-01-packages-bootstrap-roles-v2.md`.

**Tech Stack:** bash, GNU Stow, pacman/brew/apt/dnf/winget(sketch), awk-manifest parser (no yq). No test framework — bash -n + dry-run env gates (`PKG_DRY_RUN=1`) + live idempotent runs on this CachyOS thinkpad.

## Global Constraints

- Git = source of truth. All package lists vanish from `script/`; only manifest defines software.
- Moves/changes preserve repo requirements from prior sdd work: `stow -t "$HOME"` explicit everywhere, no linux-only stows on mac.
- Machine hostnames never hardcode into scripts; only `bootstrap/lib/hosts.sh` table + runtime prompt fallback.
- `PKG_DRY_RUN=1` → adapters ECHO install commands, install nothing (verification tool; not anal user API).
- Old behavior preservation: arch keeps AUR(yay/paru/bootstrap)/vscode-bin/python-xxh/services/rate-mirrors logic varbatim; mac keeps shellenv eval + brew update; debian keeps eza repo + fd symlink + zed + vscode; fedora keeps zed + vscode dnf repo; setup_zsh/fonts/git/programing/skills/rtk/mac untouched (except import path changes).
- Repo is the user's live machine; impossible-to-here hardware tests = documented runbook (mac/win), not fake claims.

---

### Task 1: manifest.yaml + lib/common.sh + lib/manifest.sh

**Files:**
- Create: `packages/manifest.yaml` (exact content in spec G1 block — all 13 groups keys INCLUDING windows + role groups; linux group adds fuzzel)
- Create: `bootstrap/lib/common.sh`
- Create: `bootstrap/lib/manifest.sh`
- Create: `bootstrap/lib/hosts.sh` (_HOST_ROLE table + resolve_role + persisted-file `~/.config/dotfiles/role`)

**Interfaces (produced, consumed by adapters/entry):**
- `DOTFILES_DIR` (default `$HOME/dotfiles`), `log() warn() die()` helpers (common.sh)
- `manifest_packages <group>` → names, space-separated; die on missing group/file (manifest.sh)
- `resolve_role` → sets ROLE=personal|company (hosts.sh); `~/.config/dotfiles/role` beats table beats prompt
- `OS_TYPE`/`DISTRO` normalizations (common.sh OS detect: Darwin→mac, /etc/os-release ID)

**Steps:**
- [ ] Write three lib files + manifest per spec G1 block verbatim (plus `fuzzel` entry present in linux group)
- [ ] `bash -n` all three
- [ ] Parser test: `source bootstrap/lib/{common,manifest}.sh; manifest_packages common | tr ' ' '\n' | head -3` expect git/zsh/stow; `manifest_packages nosuch` expect die; `manifest_packages role_company` expect empty
- [ ] Commit `feat: package manifest + bootstrap lib (common/manifest/hosts)`

### Task 2: pacman adapter + setup_basic.sh refactor

**Files:**
- Create: `bootstrap/lib/adapters/pacman.sh`
- Modify: `script/setup_basic.sh` — delete COMMON_PACKAGES array + install_mac/install_debian/install_arch/install_fedora functions; file becomes: source common/manifest libs, OS detect fallback logic (keep existing DISTRO detection), then `source bootstrap/lib/adapters/*.sh` glob (self-guarded) then `run_<distro>_install` dispatch if defined
- Move: AUR/vscode/python-xxh/services/rate-mirrors blocks from `script/setup_os/arch.sh` into pacman.sh verbatim (keep comments incl. xxh AUR pkgbuild note); DELETE `script/setup_os/` directory at this task

**Interfaces:** adapters define `run_<key>_install` where key ∈ arch|mac|debian|fedora|windows, self-guarded by `${DISTRO:-}`; `run_arch_install` calls manifest common+linux pacman loop `sudo pacman -S --needed --noconfirm $names`, then AUR/vscode/xxh/services/rate-mirrors blocks verbatim.
`PKG_DRY_RUN=1` guard: echo commands not run (precise in every adapter).

**Steps:**
- [ ] pacman.sh written (dry-run branch, guard, manifest loop, moved blocks)
- [ ] setup_basic.sh rewritten (array gone; uninstallation of common arrays = grep dead)
- [ ] `rg -n 'COMMON_PACKAGES' script/ bootstrap/` → zero hits
- [ ] delete off-setup_os dir (`git rm -r`)
- [ ] `PKG_DRY_RUN=1 DISTRO=cachyos script/setup_basic.sh` prints pacman command incl. kitty/fuzzel/zed and AUR/vscode/xxh steps — no install attempted
- [ ] `bash -n` everything touched
- [ ] Commit `feat: pacman adapter from manifest; setup_basic thin dispatcher; drop setup_os/`

### Task 3: brew adapter + Brewfile deletion + mac.sh rewrite

**Files:**
- Create: `bootstrap/lib/adapters/brew.sh` (guard `mac`; SKIP list `curl` documented: macOS ships system curl; bootstrap-if-missing + shellenv eval for /opt/homebrew & /usr/local — port EXACT eval block from current install_mac; then `brew update`; formulas = manifest common - SKIP + macos_extra; casks = macos_casks + (ROLE=personal ? role_personal : empty); dry-run branch)
- Modify: `script/setup_os/mac.sh` — replaced by thin `run_mac_install` wrapper? NOT deleted-yet: mac.sh becomes the brew adapter call site (dispatch unified in Task 2 but mac.sh file kept valid); content = source/bootstrap call
- Delete: `Brewfile`
- Modify: old `install_mac` in setup_basic.sh gone (Task 2 done); ensure shellenv/curl logic came across

**Steps:**
- [ ] brew.sh written (eval-part from install_mac preserved verbatim in the adapter)
- [ ] mac.sh trimmed to thin wrapper (guard + call install_if_missing/shellenv/update/formulas/casks from brew.sh) or deleted if Task 2 dispatcher no longer needs it; Brewfile gone
- [ ] `PKG_DRY_RUN=1 DISTRO=mac script/setup_basic.sh` prints bok of formulas+casks (role_personal cask aldente ONLY when personal)
- [ ] `rg -n 'Brewfile' script/ bootstrap/ README.md docs/` (README/doc BREW lines only — actual doc updates in Task 8)
- [ ] Commit `feat: brew adapter from manifest; drop Brewfile + mac package duplication`

### Task 4: debian + fedora adapters + win sketch

**Files:**
- Create: `bootstrap/lib/adapters/debian.sh`, `bootstrap/lib/adapters/fedora.sh`, `bootstrap/lib/adapters/win.sh`
- Contents: verbatim-move today's setup_basic install_debian/install_fedora bodies into adapters (eza upstream deb repo + gpg keyring steps preserved; fd-find→fd symlink; dnf; zed installer + vscode repo steps from old setup_os files preserved); win.sh = manifest `windows` group → print `winget install --id ...` commands + exit 0

**Steps:**
- [ ] adapters written, guards correct, dry-run prints expected
- [ ] `PKG_DRY_RUN=1 DISTRO=debian script/setup_basic.sh` prints full apt command lists (no real changes)
- [ ] `bash -n` clean
- [ ] Commit `feat: debian/fedora adapters from manifest; winget sketch adapter`

### Task 5: roles/ + stow integration

**Files:**
- Create: `roles/personal/.gitkeep`, `roles/company/.gitkeep`
- Modify: `install.sh` — stow block: common group unchanged + `-d linux` guard piece REMAIN, add `-d roles $ROLE` line (after linux group) with guard `[[ -n "${ROLE:-}" ]]`
- Consumes: ROLE from hosts.sh resolution (bootstrap integration Task 6; interim = install.sh resolves role itself by sourcing bootstrap/lib/hosts.sh when present)

**Steps:**
- [ ] roles dirs created + gitkeep'd
- [ ] install.sh: resolve ROLE (source hosts.sh) + extend stow block (`-d roles "$ROLE"` only non-empty)
- [ ] `stow -n -t "$HOME" -d roles personal` dry run passes (folding ignored since roles/personal/* only gitkeep? `stow -n -d roles personal` on .gitkeep-only = vp empty package benign? Verify: if stow errors on empty pkg, task adds `roles/personal/dot-config-example` placeholder? KEEP simple: verify real behavior; if empty-package error, add a harmless placeholder file (e.g. `roles/personal/.keep` only) — record outcome)
- [ ] Commit `feat: role stow packages + install.sh role integration (personal/company)`

### Task 6: bootstrap entry + subcommands + install.sh shim

**Files:**
- Create: `bootstrap` (top-level, executable, no ext) — arg parser: none|packages|config|ai|--update
- Create: `bootstrap/lib/full.sh` (verbatim invocation-flow port from today's install.sh in current order: net check, OS detect, chmod, git-init, [packages adapter stage], stow stage, setup_git, mac defaults (mac only, non-update), fonts, zsh, programing, skills, rtk; --update skips packages/stow/fonts/gitemail/macdefaults per existing semantics)
- Modify: `install.sh` → 3-line `exec` shim
- Consume: lib/common+manifest+hosts, adapters (Tasks 1-4), roles stow (Task 5)
- A) `./bootstrap packages` = source lib + setup_basic.sh (which now dispatches adapters) full-pass (no --update shortcut path)
- B) `./bootstrap config` = the install.sh stow block content moved verbatim (incl. `-d linux` guard, roles, `-t $HOME`)
- C) `./bootstrap ai` = `script/setup_skills.sh` + `script/setup_rtk.sh`
- D) `./bootstrap` (no args) = full.sh + explicit steps + final-next-steps echo block (as today)
- E) `./bootstrap --update` = full.sh in update mode (skip packages/stow/fonts/macdefaults; zsh+skills get --update)
- chmod +x bootstrap

**Steps:**
- [ ] bootstrap written + solutions to subcommand mapping (packages → setup_basic.sh path; config → stow block; ai → those two setup scripts; none → full.sh)
- [ ] install.sh shim + chmod preserved
- [ ] `bash -n bootstrap bootstrap/lib/full.sh install.sh`
- [ ] `PKG_DRY_RUN=1 ./bootstrap packages` on thinkpad — prints pacman install command (no real action)
- [ ] `./bootstrap config` idempotent dry/real stow on thinkpad — exit 0 (verify no conflict; existing links already `--restow`-able)
- [ ] `./bootstrap ai` brief safe re-run (harmless)
- [ ] Commit `feat: bootstrap entry with packages/config/ai subcommands; install.sh shim`

### Task 7: AI-skills CLI + plan.md deletion

**Files:**
- Create: `bootstrap/lib/ai.sh` (impl list/update/status; described in spec G5: personal/external split-view table)
- Modify: `bootstrap` — `ai` subcommand accepts `ai`, `ai list`, `ai update`, `ai status`
- Delete: `docs/plan.md`
- Modify: `script/setup_skills.sh` — no behavior change; only add a one-line comment pointing at bootstrap ai wrappers if it clarifies

**Steps:**
- [ ] ai.sh: `list` (submodule table from `git submodule status` + personal/external split-off `skills/README.md` conventions), `update` (`git submodule update --remote --merge` then re-symlink via setup_skills.sh re-run), `status` (submodule status raw)
- [ ] `./bootstrap ai list` / `status` / `update` on thinkpad all run clean (update = real pull; acceptable here per continuous-execution user consent — note in report if skipped)
- [ ] docs/plan.md rm'd
- [ ] Commit `feat: bootstrap ai subcommands (skills list/update/status); drop superseded skills npx plan`

### Task 8: docs + secrets + M5 runbook

**Files:**
- Modify: `README.md` — new layout tree (bootstrap/, packages/manifest, roles/, no Brewfile), subcommands table, secrets section (never-commit rule + `~/.config/zsh/.zshrc.local` pattern + `~/.config/dotfiles/role`)
- Modify: `script/README.md` — setup_os/ section replaced by adapters table; execution order updated to bootstrap flow, stow line text = Task 5 wording + roles
- Modify: `docs/install.flow.mmd` — rewrite flow: bootstrap subcommands + manifest→adapters
- Create: `docs/M5-RUNBOOK.md` — clone URL, `./bootstrap` expected steps (brew bootstrap, shellenv, update, formulas from manifest, casks, stow, fonts? mac fonts path — setup_fonts.sh already handles Library/Fonts), what post-install to fill in (hosts.sh hostname + `./bootstrap config`), and what's SKETCHY on mac (win/winget stays). Include company-mac caveat (role=company → no aldente)
- Sweep: no `Brewfile` refs outside git history; no stale apt/dnf/`setup_os` descriptions.

**Steps:**
- [ ] Docs written per files
- [ ] `rg -n 'Brewfile' README.md docs/ script/` — zero (history only)
- [ ] `rg -n 'setup_os/' README.md script/README.md docs/install.flow.mmd` — zero (or "removed" mentions)
- [ ] Commit `docs: manifest/bootstrap architecture docs, secrets rule, M5 runbook`

### Task 9: End-to-end verification (thinkpad live)

**Files:** read-only except real `./bootstrap` runs (user machine, continuous-execution consent)

**Steps:**
- [ ] `bash -n bootstrap bootstrap/lib/*.sh bootstrap/lib/adapters/*.sh install.sh script/*.sh script/setup_os/*.sh` (before deletion happens if order differs) — clean
- [ ] `manifest_packages` for every group — prints names, no die
- [ ] `PKG_DRY_RUN=1 ./bootstrap packages | head -30` — arch path shows pacman formulas incl. kitty/fuzzel + AUR/vscode/xxh prints
- [ ] `./bootstrap config` — idempotent stow (exit 0, no conflicts; $HOME links verified valid after)
- [ ] `./bootstrap --update` — full live update flow (idempotent; updates skills submodule; plugins re-pull) — exit 0
- [ ] `git status --short` clean at end
- [ ] Report + ledger, then final whole-branch review dispatch (most capable model)

## Self-review notes (controller-generated)

- Spec G1↔Task 1 covered; G2↔Tasks 2-4; G3↔Task 5+hosts; G4↔Task 6; G5↔Task 7; G6↔Task 8+9. Windows sketch = win.sh only.
- Risks called out: brew adapter SKIP-list semantics for curl; empty-dir stow behavior (Task 5 verification step); apt eza repo steps preserved (Task 4). HOST_ROLE placeholder values get real entries on first real mac install.
