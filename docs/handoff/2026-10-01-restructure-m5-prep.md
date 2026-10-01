# Session Handoff — dotfiles restructure + M5 prep (2026-10-01)

## Where things stand

Repo: `~/dotfiles`, branch `main`, pushed to `origin/main`. Status: clean except `?? new-spec.md` (untracked spec source dropped by user; move to `docs/` or ignore on next pass).

Two workstreams completed this session:

1. **Architecture-v2 restructure** — executed via subagent-driven development, all tasks reviewed clean, final review clean.
   - Master spec: `docs/superpowers/specs/2026-10-01-packages-bootstrap-roles-v2.md`
   - Plan: `docs/superpowers/plans/2026-10-01-architecture-v2.md`
   - Result: `packages/manifest.yaml` single package source; `bootstrap` entry (`packages|config|ai|list|--update`); `bootstrap.d/lib/` + 5 adapters (pacman/brew/debian/fedora/winget-sketch); `roles/{personal,company}`; `install.sh` = 3-line shim; `Brewfile`, `script/setup_os/`, `docs/plan.md` deleted.
2. **M5 prep + small features** — `justfile` added; atuin packaged + zsh init; opencode v2 routed via manifest (arch: AUR `opencode2-bin`, mac: brew tap `anomalyco/tap/opencode-v2`); curl route retired; wallpaper moved back to repo root `wallpaper/` (common asset, refs updated); stale `~/.opencode/` curl-installer leftovers removed from thinkpad; live `~/.config` stow links repaired on thinkpad; mac defaults rounds in `script/setup_mac.sh` (details below).

## Current mac defaults state (`script/setup_mac.sh`)

Set: hidden files, press-and-hold off, fast key repeat, battery %, always-scrollbars, Finder path/status bars, screenshots dir + no thumbnail, no DS_Store on network, tap-to-click, three-finger drag, reduce transparency, trackpad tracking `2.4` (80% of 3.0 max) + `-currentHost`, scroll speed max `7` both domains, dock `tilesize 36` + magnification **off**, text substitutions all off (capitalization/dash/period/quote/spelling), Fn keys as F-keys (`fnState true`).

Deliberately NOT set (user may add later): full keyboard access (`AppleKeyboardUIMode`), `mru-spaces off`, hot corners off, Dock autohide. Display "More Space" scaling has no `defaults` command on Apple Silicon — script carries a commented `displayplacer` recipe instead.

## Key decisions made (do not relitigate without cause)

- Stow kept, chezmoi rejected (symlink needs only). npx-skills rejected (breaks Git-source-of-truth); submodules retained; skills CLI = `bootstrap ai list|update|status`.
- `bootstrap/` dir renamed `bootstrap.d/` (POSIX forbids `bootstrap` file + dir); spec text updated accordingly.
- Manifest keys: `common linux macos_casks macos_extra role_personal role_company windows`. kitty/alacritty excluded from `common` (brew wants them as casks). Brew adapter skips `curl` (system curl kept). `PKG_DRY_RUN=1` env gate everywhere; stow always `-t "$HOME"` explicit.
- `roles/` packages are `.gitkeep`-only placeholders with a portable find-guard (no GNU `-quit`); aldente is the only real personal/company difference (manifest, not configs).
- Brave on arch = `brave-bin` via existing AUR auto-route (repo-probe, not suffix heuristic, in live runs).
- opencode: v1 untouched at `~/.bun/bin/opencode` (1.18.34, manually installed, NOT in manifest — known gap); v2 = `/usr/bin/opencode2` (AUR beta, manifest-managed, mac via brew tap).
- Trackpad 80% = `2.4`; scroll `7` is "past any slider position", not a proven exact max — if M5 scroll feels capped, one logout/login applies it.

## Open / known gaps

- Mac side **never executed live** (no mac hardware in this session): brew shellenv eval, tap formula, stow on mac, `setup_mac.sh` values — all code-reviewed only. Verified paths exist via `PKG_DRY_RUN` where possible.
- `bootstrap.d/lib/hosts.sh` hostname table still has placeholders for M3/M5/windows rows; real values go in on first M5 install (see `docs/M5-RUNBOOK.md`).
- `sudo` needs a TTY password on this machine — shellcheck never ran; anything needing sudo/AUR install must run in the user's own terminal.
- `new-spec.md` untracked at root — user's spec source; not yet filed.
- `utility/` missing from `.stow-local-ignore` (pre-existing, zero live harm since install never runs bare `stow .`).
- `ai list` name-split assumes no literal `" ("` in submodule names; `%-22s` pad narrower than longest name (cosmetic).
- Doc nits parked: `README:84` lib-source detail, mise wording, flow `MATCH` label, `ai list foo` ignores extra args.

## Suggested continuation

- M5 day: follow `docs/M5-RUNBOOK.md` (clone → hosts.sh hostname → `./bootstrap` or `just all`).
- If touching bootstrap/adapters: re-read the master spec + relevant plan tasks first; keep `PKG_DRY_RUN=1` gate and explicit `-t "$HOME"` on every stow call.

## Suggested skills for the next agent

- `caveman` (full) — user's standing chat-output mode.
- `verification-before-completion` — before claiming any fix/install works.
- `subagent-driven-development` — if executing any multi-task plan from the plans dir.
- `karpathy-guidelines` — before writing or refactoring shell code.
- `brainstorming` — before any new creative/restructure work (per repo AGENTS.md).
- `explaining-concepts` — if the user asks "what is X / should I use X or Y".
- `customize-opencode` — only when editing opencode's own config.
