# Session Handoff — M5 live-install debugging (2026-10-01, evening)

Prior handoff (restructure + M5 prep): `docs/handoff/2026-10-01-restructure-m5-prep.md`. Read it first for locked decisions. This doc covers only what happened since: the first real `./bootstrap` run on the personal MacBook M5.

## Machine state

- Thinkpad (CachyOS): healthy, in sync with `origin/main`.
- M5 (personal mac): mid-install, several failures found and fixed from the thinkpad side. User runs commands on the M5 and pastes results back.
- Company M3: untouched.

## Failures found on the M5 so far (all fixed, pushed)

1. `git` unusable on fresh mac — `git` is a stub demanding Xcode/CLT.
   Fix: runbook step 0 = `xcode-select --install` first. Commit `dcc43e9`. (`xcode-select: note: install requested...` is normal output, not an error.)
2. `./install.sh` → `line 22 thinkpad: unbound variable`.
   Root cause: macOS `/bin/bash` is 3.2, no associative arrays; `declare -A HOST_ROLE=(["thinkpad-p14s"]=...)` subscripts evaluated as arithmetic under `set -u`. Fix: `bootstrap.d/lib/hosts.sh` table is now a portable `case` function (`_host_role_for`). Verified same resolution. Commit `ac2295f`. Audit: no other bash-4-isms (`declare -A|mapfile|readarray|[[ -v`) in `bootstrap.d/ script/`.
3. `brew install --cask` died on **alacritty** (Gatekeeper-blocked) → under `set -e` the whole cask line aborted → stow never installed → config stage died at its `command -v stow` gate (looked like "no zsh, no stow").
   Fix: alacritty removed from manifest `macos_casks` (kitty is the mac terminal; alacritty config still stows). Commit `1bd7d15`. Lesson re-confirmed: one bad package must not kill a whole install line.
4. Config stage hard-exited when stow missing.
   Fix: `bootstrap.d/lib/config.sh` now self-installs stow per-DISTRO (mac: `brew install stow`) instead of aborting. Verified with fake-brew harness + live `./bootstrap config` on thinkpad. Commit `c386519`. Still unexplained from logs: why the *formula* step failed on the M5 (tap formula `anomalyco/tap/opencode-v2` verified valid — root-level `Formula`, installs binary `opencode`, `conflicts_with "opencode"`). Asked user for `./bootstrap packages` tail output; answer pending.
5. mac-defaults stage died at `com.apple.universalaccess` (`Couldn't write domain ...; exiting`), aborting everything after it under `set -e` (trackpad/scroll/dock/fn-keys/killalls never applied).
   Fix: `script/setup_mac.sh` — every `defaults write` now goes through `dflt()` warn-and-continue wrapper. Commit `77c33fb`. Script spelling of `universalaccess` verified correct.

## In-flight (BLOCKED on user diagnostics from the M5)

6. User reports `AppleShowAllFiles -bool true` and `ApplePressAndHoldEnabled -bool false` also warn (= fail) — i.e. possibly ALL `defaults write` calls fail on this machine, `universalaccess` was just the first domino. Environmental suspects: wrong user/HOME, locked `~/Library/Preferences`, no Aqua/cfprefsd session, MDM (unlikely — personal machine).
   Asked user to run and paste:
   ```bash
   whoami; echo "HOME=$HOME"
   defaults write NSGlobalDomain AppleShowAllFiles -bool true; echo "rc=$?"
   ls -la ~/Library/Preferences/.GlobalPreferences.plist
   ```
   Do not change `setup_mac.sh` further until that output arrives.

## Other session facts worth knowing

- Raycast added to manifest `macos_casks` (all macs, role-ungated). Commit `e154a91`.
- Mac defaults settled this session: transparency off, trackpad `2.4` (80% of 3.0 max), scroll `7`, dock `tilesize 36` + magnification **off** (user declined), text substitutions off, Fn-as-F-keys. Still NOT set (user deferred): full keyboard access, `mru-spaces` off, hot corners off. User will do Karabiner/Aerospace/skhd themselves.
- Wallpaper moved back to repo-root `wallpaper/` (common asset); live-applied on thinkpad via `awww img` after the move (session had gone black).
- opencode: v1 untouched (`~/.bun/bin/opencode` 1.18.34, NOT in manifest — known gap); v2 = `/usr/bin/opencode2` beta via AUR on thinkpad, manifest-managed (linux `opencode2-bin`, mac brew tap); stale `~/.opencode/` curl leftovers deleted from thinkpad.
- `justfile` added (`just install|update|upgrade|plan|list|...`); M5 flow = `just all` after clone.
- `docs/M5-RUNBOOK.md` updated (CLT step 0, real clone URL).
- Repo clean except `?? new-spec.md` (user's untracked spec source, still unfiled).

## Suggested skills for the next agent

- `caveman` (full) — standing output mode.
- `verification-before-completion` — before claiming any mac fix works (mac behavior cannot be reproduced from the thinkpad; demand pasted output).
- `diagnosing-bugs` / `systematic-debugging` — the M5 `defaults` failures are an active unknown-cause bug.
- `karpathy-guidelines` — before touching shell code.
- `subagent-driven-development` — only if a multi-task plan emerges.
