# Session Handoff — M5 keyboard-driven setup (2026-10-02 → 2026-10-04)

Prior handoff: `docs/handoff/2026-10-01-m5-install-debug.md` (first `./bootstrap`
run, 5 fixes). This doc covers everything since. Session runs **on the M5**
(`macbookpro-m5.local`, Darwin 25.3, nvim 0.12.5, `ROLE=personal`).

## HEADLINE: 27 commits unpushed

`git rev-list --count origin/main..main` = **27**. Nothing since `9a2a18e` has
reached origin. The Thinkpad is 27 behind; Company M3 untouched. `git push`
needs the user's GitHub auth (no credential helper in agent shells):

```bash
git push origin main   # from a terminal with auth
```

## Machine state (M5)

- Full `./bootstrap` completed with `Installation Complete!` (log in untracked
  `log.txt` at repo root — user's copy, leave it).
- `./bootstrap packages` re-runs are idempotent; per-package warn-and-continue
  holds (one bad formula/cask can't abort the run).
- Dirty files deliberately left alone: `M nvim/.config/nvim/lazy-lock.json`
  (plugin pins drifted via `:Lazy`), `M wallpaper/profile-nagato.jpg`,
  `?? log.txt .DS_Store opencode/.config/opencode/*`.
- Damien's `mac/aerospace/.aerospace.toml` has 1 uncommitted local line change
  (was true at last check — verify with `git diff` before pushing).

## Landed fixes (all in the 27, all verified live on the M5)

1. **`dflt()` dropped the `write` verb** (`77c33fb` follow-up, commit
   `8913d14`): every `defaults` call failed; wrapper now inserts `write`
   (with `-currentHost` ordering preserved). Same commit made brew installs
   per-package. Only `com.apple.universalaccess` still warns (environmental,
   non-fatal).
2. **Brew bin missing from shells** (`3e1177d`): stowed `.zshrc` bypassed the
   brew-installer `.zprofile` line; shellenv now evals first in `.zshrc`.
3. **tpm `returned 1` + vim-tmux-navigator dead** (saga, final: `9f23b85`):
   root cause is GUI-launched kitty spawning the tmux server with bare system
   PATH and no shell in between, so tpm children can't find the `tmux`
   binary. Dead ends, in order: zshrc fix (wrong layer), `kill-server`
   (same broken parent env reborn), LaunchAgent `setenv` route (verified
   dead — fresh bootstrap exit 0 yet `launchctl getenv PATH` empty, plus a
   wasted reboot). Working fix: one guarded `set-environment -g PATH` line
   in `tmux.conf` (`-d /opt/homebrew/bin` skips Linux). Verified: global
   PATH correct, `C-h` navigator binding present in live server.
   PENDING: user must `Cmd+Q` kitty fully + reopen, then
   `tmux list-keys -T root | grep " C-h "` must print the navigator line.
4. **nvim dashboard E5108** (`fc02b5f`): upstream `nvchad/ui` bug
   (v3.0 HEAD == pinned commit, no upstream fix) — `key_movements` returns
   nil when cursor sits off-button (mouse click, scroll, `gg`), crashing
   `nvim_win_set_cursor`. `lua/autocmds.lua` wraps buffer-local j/k with
   plain-motion fallback. Reproduced exact error headless, then ALL PASS
   incl. healthy-path preservation.
5. **Mission Control tiny windows under AeroSpace** (`3a10243`): known
   upstream quirk (guide: "A note on mission control"). Fix:
   `expose-group-apps -bool true` in `setup_mac.sh`. Applied live; user to
   confirm with 4-finger swipe.
6. **Double-click speed** (`dc4d804`): user's working value `1.7` baked into
   `setup_mac.sh` (read live; higher = more forgiving). Note: ByHost domain
   has no override; Karabiner/Neru/AeroSpace were NOT running when it failed,
   so event-tap interference was ruled out.
7. **Stale mattpocock skill path** (`c94b0f6`): `writing-great-skills` →
   `writing-for-agents` (upstream rename).

## Added (manifest, configs)

- **Bitwarden + Brave** (`03c748f`): per-OS groups (Arch `[extra]`
  verified, brew casks verified 200 on formulae API, winget IDs canonical).
  NOT in `common` (no brew formula/apt package for Bitwarden) — GUI apps
  stay per-OS like firefox/zed.
- **AeroSpace + Karabiner-Elements + Neru** (`301717b`): `role_personal`
  casks only (system-level tools; company M3 must not get them unasked).
  AeroSpace tap is `nikitabobko/homebrew-tap` (shorthand `nikitabobko/tap`).
- **AeroSpace config** (`0c16576`, `def3198`, `7c73468`): bundled 0.21.3
  default + Hyprland-style Alt bindings (SUPER→ALT translation: Cmd belongs
  to apps on mac), gaps 8, auto-reload on, `Alt+Enter` kitty, letter
  workspaces dropped, unhide-apps on. Lives at `mac/aerospace/`, stowed
  mac-gated (user caught the first all-platform placement — fixed).
  AeroSpace running (pid seen live); needs Accessibility grant + relaunch to
  actually tile. `start-at-login` still false — flip when user is happy.
- **Karabiner caps→ctrl** (`aedd65b`): `mac/karabiner/` stowed mac-gated.
  Karabiner installed but **Input Monitoring grant status unknown**; user to
  confirm `Caps+C` interrupts. Warning given: edit repo file, GUI rewrites
  kill the symlink (already happened once — adopted the minimized rewrite,
  caps mapping intact).
- **Neru** (`0ece8af`): installed, launchd service registered and healthy
  (`neru doctor` all green, v1.56.0), permissions granted, hints fixed to
  `hints --action left_click` (bare `hints` showed labels but never clicked).
  Config at `mac/neru/`, stowed mac-gated. User retesting label-click.
- **Kitty**: starts maximized (`remember_window_size`, `6aef633`).
- **README** (`4ba7867`): rewritten keyboard-driven (Hyprland/AeroSpace
  tables, tmux/nvim/shell/Neru/keys/launcher), plus staleness fixes (real
  clone URL, current cask lists, `mac/` contents).

## Tried and reverted (nothing lingering)

- `nightlight` CLI for Night Shift → native Settings manual steps.
- `displayplacer` for More Space → native Settings manual.
- `hidutil` caps→ctrl + login agent → Karabiner instead (live state fully
  restored: mapping cleared, agent removed).
- kitty `map cmd+t new_window` → wrong layer; global launch hotkey belongs
  in Raycast (per-app hotkey, manual) or Shortcuts app. User chose
  Shortcuts-app route for Cmd+T→Kitty.

## Policy discovered (do not relitigate lightly)

- **Native macOS only, no new tools**, unless user explicitly asks (their
  words: "use default macos dont add anything"). Night Shift / More Space /
  True Tone / auto-brightness are documented manual steps by policy.
- **Confirm layer + behavior before writing.** Several implement→revert
  cycles this session (kitty-vs-system, CLI-vs-native, hidutil-vs-Karabiner)
  cost trust. One clarifying question up front beats a revert commit.
- User replies tersely and misclicks option prompts — re-asking is supported,
  don't treat first answer as sacred when they say misclick.

## Agent compliance (late this session)

`opencode/.config/opencode/AGENTS.md` was only read on 2026-10-03 after user
prompt. Now active: caveman-full chat output (persisted files stay normal
prose), `karpathy-guidelines` + `verification-before-completion` skills
loaded, `rtk` 0.50.0 present for noisy command output.

## Suggested skills for next agent

- `caveman` (full) — standing output mode.
- `verification-before-completion` — mac behavior can't be reproduced
  elsewhere; demand pasted output or live reads.
- `systematic-debugging` — for the next live-on-M5 unknown.
- `karpathy-guidelines` — before touching shell/config code.
