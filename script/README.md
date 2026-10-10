# Scripts

Called by `./bootstrap` (full flow) in order. Each script is standalone and idempotent (safe to re-run).

## Execution order

`bootstrap` → full flow lives in `bootstrap.d/lib/full.sh` (packages & steps) and `bootstrap.d/lib/config.sh` (stow stage).

```
bootstrap / bootstrap --update
├── 0. lib bootstrap            # common.sh: OS/DISTRO detect, exports
├── 1. internet check           # curl github.com (exit 1 if unreachable)
├── 2. setup_basic.sh           # manifest → distro adapter  (skipped in --update)
│   └── adapters/<os>.sh        # pacman | brew | debian | fedora | win(sketch)
│       (brew: brew bootstrap → shellenv eval → update → formulas → casks,
│        formulas = manifest common + macos_extra minus curl;
│        casks = manifest macos_casks + role_personal/aldente when ROLE=personal)
├── 3. setup_git.sh             # interactive git user.name/user.email (skipped in --update)
├── 4. config.sh (stow)         # stow common pkgs on EVERY platform
│   │                           #   (zsh tmux nvim kitty alacritty ideavim opencode xxh);
│   │                           #   non-mac: stow -d linux hypr waybar gtk qt fontconfig;
│   │                           #   roles/<role> stow only when it holds real content
│   │                           #   (gitkeep-only dir is skipped — never plants .gitkeep in $HOME)
│   └── resolve_role            # hosts.sh: ~/.config/dotfiles/role → HOST_ROLE lookup → prompt
│                               # (config.sh resolves the role BEFORE stowing, via hosts.sh)
├── 5. setup_mac.sh             # macOS-only: Finder/trackpad/keyboard defaults (skipped in --update)
├── 6. setup_fonts.sh           # symlink fonts into OS font dir (skipped in --update)
│                               #   fonts run AFTER stow, BEFORE zsh
├── 7. setup_zsh.sh             # clone zsh plugins + tpm + chsh -s zsh (--update mode in --update)
├── 8. setup_programing.sh      # mise (go/java/node/rust), GitNexus, rtk
├── 9. setup_skills.sh          # init skill submodules + symlink skills into agent dirs
├── 10. setup_graphify.sh       # graphify CLI (uv) + /graphify skill for agents
└── 11. setup_rtk.sh            # activate rtk for opencode (installs opencode plugin) — RTK LAST
```

Exact step order is the code of `bootstrap.d/lib/full.sh` + `bootstrap.d/lib/config.sh`.

## Adapters (`bootstrap.d/lib/adapters/`)

- **`bootstrap.d/lib/adapters/<os>.sh`** = installs **packages** for that OS family, reading `packages/manifest.yaml` (single source of truth — no package lists in scripts):

| Adapter | OS family | What it installs |
|---|---|---|
| `pacman.sh` | arch/cachyos/eos/… | pacman (manifest `common` + `linux`); paru AUR helper bootstrap; VS Code (`visual-studio-code-bin`) + `python-xxh` from AUR; systemctl services; `cachyos-rate-mirrors` on CachyOS |
| `brew.sh` | macOS | brew if missing → `shellenv` eval → `brew update` → formulas (`common` + `macos_extra`, skip `curl`) → casks (`macos_casks` + `role_personal` Aldente when personal) |
| `debian.sh` | Debian/Ubuntu | fd-find→fd symlink, zed installer, VS Code MS apt repo |
| `fedora.sh` | Fedora | zed installer, VS Code MS dnf repo |
| `win.sh` | Windows | winget sketch — prints only, not wired up yet |

- **Top-level `script/setup_*.sh`** = other concerns: `setup_zsh.sh` (plugins + chsh), `setup_fonts.sh` (fonts), `setup_skills.sh` (agent skill submodules), `setup_programing.sh` (toolchains), `setup_mac.sh` (macOS system **defaults** — config, not packages).

So on mac: the brew adapter installs packages (formulas + casks), while `setup_mac.sh` runs `defaults write …` (Finder/trackpad config). Two distinct jobs → two files.

## Self-guard pattern

Each `bootstrap.d/lib/adapters/<os>.sh` begins with a "build tag" — it defines nothing when sourced for the wrong OS:

```bash
case "${DISTRO:-}" in
  mac) ;;
  *)
    [[ "${BASH_SOURCE[0]:-${0}}" == "${0}" ]] && exit 0 || return 0 ;;
esac
```

The `BASH_SOURCE[0] == $0` test distinguishes "executed directly" (exit) from "sourced" (return), so each file is also runnable standalone for testing.

**Adding a new OS family** = drop a new `bootstrap.d/lib/adapters/<family>.sh` with its own `${DISTRO}` guard. No central `case` to update — `script/setup_basic.sh`'s `source bootstrap.d/lib/adapters/*.sh` glob picks it up automatically.

## Scripts

### `setup_basic.sh`
Thin dispatcher: sources `bootstrap.d/lib/{common,manifest,hosts}.sh`, sources every matching `bootstrap.d/lib/adapters/*.sh` (self-guarded, resolves `ROLE`), and calls the matching `run_*_install`. Package names come from `packages/manifest.yaml`. `PKG_DRY_RUN=1` previews the plan.

### macOS packages
`bootstrap.d/lib/adapters/brew.sh` installs brew formulas (manifest `common` + `macos_extra`; system `curl` is kept and skipped) and casks (`macos_casks`, plus `role_personal`/aldente when `ROLE=personal`). `brew bundle` is retired — `packages/manifest.yaml` is the single source of truth.

### `setup_git.sh`
Prompts interactively for `user.name` and `user.email` if not already set in global git config. Idempotent — skips a key when already configured or when given empty input. (skipped in `--update`)

### `setup_mac.sh`
macOS system **defaults** (Finder, trackpad, keyboard, screenshots). Only called on macOS. Package installs live in the brew adapter (`bootstrap.d/lib/adapters/brew.sh`), not here. (skipped in `--update`)

### `setup_fonts.sh`
Symlinks font files from `dotfiles/fonts/` into the OS font directory. (skipped in `--update`)
- **Linux**: `~/.local/share/fonts/` + `fc-cache -f`
- **macOS**: `~/Library/Fonts/`
- **Windows**: copies (symlinks not reliable for Windows font dir)

### `setup_zsh.sh [--update]`
Clones zsh plugins into `~/.config/zsh/plugins/` and tpm into `~/.config/tmux/plugins/`. Sets zsh as default shell via `chsh`.
- `--update`: `git pull --ff-only` in each plugin dir to get latest

### `setup_programing.sh`
Installs dev toolchains via **mise** (single runtime manager, replaces rustup/SDKMAN):
- **mise** manages go, java, node, rust from `~/dotfiles/mise.toml` — `mise install` provisions all
- **GitNexus**: `mise exec -- npm install -g gitnexus` (uses mise's node)
- **rtk**: paru/yay on arch, brew on mac, curl script as fallback

### `setup_skills.sh [--update]`
Inits skill submodules in `dotfiles/skills/` and symlinks each skill into agent discovery dirs (`~/.config/opencode/skills/`, `~/.claude/skills/`, `~/.codex/skills/`, `~/.agents/skills/`).
- `--update`: `git submodule update --remote --merge` first, then re-symlink

See `../skills/README.md` for adding/removing/pinning skills.

### `setup_graphify.sh`
Installs the [graphify](https://github.com/Graphify-Labs/graphify) knowledge-graph CLI and registers its `/graphify` skill with the AI assistants.
- **uv**: installed via mise (`mise use -g uv@latest`) when missing; falls back to `mise exec -- uv` if its shims aren't on PATH.
- **graphify**: `uv tool install graphifyy` (the PyPI name has a double-y; the command is `graphify`).
- **skill**: `graphify install --platform <p>` for `opencode`, `claude`, `codex`, `agents`. Run from `$HOME` so opencode's always-on plugin lands at `~/.opencode` (a discovery ancestor of every project) instead of inside a project checkout. Idempotent; warns and continues on failure.
- **always-on (opencode)**: `graphify opencode install` additionally writes an `AGENTS.md` instruction block + the `tool.execute.before` plugin — also from `$HOME`, so they land at `~/AGENTS.md` and `~/.opencode`.

Per project: build a graph with `/graphify .`, then query it with `graphify query "<question>"`.

### `setup_rtk.sh`
Activates rtk for opencode by running `rtk init -g --opencode --no-patch`, which installs the opencode plugin at `~/.config/opencode/plugins/rtk.ts`. The plugin auto-rewrites bash commands to their rtk equivalents for token savings. Idempotent — skips if the plugin is already up to date. Requires the rtk binary in PATH (installed by `setup_programing.sh`).

Note: `setup_programing.sh` (which installs rtk itself) runs BEFORE `setup_rtk.sh` — keep `RTK last` when adding steps.

## Flags

| Caller | Flag | Effect |
|---|---|---|
| `bootstrap` | `--update` | Full flow in update mode: forward `--update` to `setup_zsh.sh` + `setup_skills.sh`; skip the slow idempotent steps (base packages, git identity, stow, mac defaults, fonts) — designed for re-syncing plugins/skills without reinstalling the world |
| `setup_zsh.sh` | `--update` | Pull latest plugin versions |
| `setup_skills.sh` | `--update` | Pull latest skill submodule commits |
| `setup_basic.sh` (env) | `PKG_DRY_RUN=1` | Preview what the adapter would install (nothing actually installed) |

## Re-running

All steps are idempotent — safe to re-run anytime. They skip already-installed items and only create/update what's missing. `./bootstrap` runs the whole thing; `./bootstrap --update` is a faster re-sync that skips package managers/git/stow/fonts and just refreshes plugins + skills.
