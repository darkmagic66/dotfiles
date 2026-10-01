# hyprsunset warm filter not applied to mirrored monitor

> Fix plan & reference. Not executed yet — see **Status**.
> Tracking: https://github.com/hyprwm/hyprsunset/issues/85 (open, no fix)

## Status

Open upstream bug, **not fixed**. Confirmed still broken on this machine:

| Component | Version |
| --- | --- |
| Hyprland | `0.56.2-1` (`/usr/bin/Hyprland`, pkg `hyprland`) |
| hyprsunset | `v0.4.0` (running: `hyprsunset -t 3000`) |
| Compositor launch | TTY1 direct (`Hyprland`), no display manager, no `uwsm` |
| Monitors | ThinkPad `eDP-1` (source) + `HDMI-A-1` mirroring it |

Selected fix path: **A — Hyprland source patch + local-prefix build** (survives updates), PR submitted upstream **later**. Alternatives B/C are documented at the bottom for reference.

## Root cause

The breakage is in **Hyprland**, not in `hyprsunset.conf` and not in `modules/monitors.lua`. When a monitor mirrors another (`mirror = "eDP-1"`), Hyprland advertises only **one** `wl_output` global (the source, `eDP-1`) to Wayland clients. The mirrored monitor (`HDMI-A-1`) is never exposed as a bindable output, so hyprsunset never learns it exists and never sends a CTM for it. On commit, Hyprland's `CTMControl.cpp` iterates all monitors and applies each one's CTM by name — and for any monitor not in the CTM map (the mirror), it falls back to `identity` = no warm filter.

Live evidence from this machine:

```
$ hyprctl monitors all | rg '^Monitor|mirrorOf'
Monitor eDP-1 (ID 0):     mirrorOf: none    ← source
Monitor HDMI-A-1 (ID 1):  mirrorOf: 0       ← mirrors eDP-1

$ hyprsunset --verbose -t 3000
┏ hyprsunset v0.4.0 ━━
┣ Found hyprland-ctm-control-v1 supported with version 2, binding to v2
┣ Found new output with ID 71, binding
┣ Found 1 output(s), applying CTMs          ← only eDP-1 advertised
┣ Calculated the CTM to be [mat3x3: 1, 0, 0, 0, 0.694903, 0, 0, 0, 0.431048]
```

Code path, `src/protocols/CTMControl.cpp` (verified against the `v0.56.2` tag):

```cpp
// set_ctm_for_output handler — stores CTM keyed by monitor name
m_ctms[PMONITOR->m_name] = MAT;   // hyprsunset only ever sets "eDP-1"

// commit handler — applies per monitor
m_resource->setCommit([this](CHyprlandCtmControlManagerV1* r) {
    if (m_blocked) return;
    for (auto& m : State::monitorState()->monitors()) {
        if (!m_ctms.contains(m->m_name)) {
            PROTO::ctm->setCTM(m, Mat3x3::identity());   // ← HDMI-A-1 lands here
            continue;
        }
        PROTO::ctm->setCTM(m, m_ctms.at(m->m_name));      // ← eDP-1 lands here
    }
});
```

`CMonitor` already carries the mirror topology (`m_mirrorOf` / `m_mirrors`, in `src/output/Monitor.hpp`), but the commit loop never consults it — so the source's CTM is never copied onto the mirroring monitor's CRTC. Each monitor keeps its own KMS CRTC, so per-connector CTM works on the Intel iGPU; the data is there, just not propagated.

## Why config edits can't fix it

`~/.config/hypr/hyprsunset.conf` (3000K all-day profile) is correct and unchanged. `~/.config/hypr/modules/monitors.lua` (`mirror = "eDP-1"`) is correct and unchanged. No client-side or compositor-config change can make Hyprland apply the source's CTM to a mirrored output — that propagation is missing from the compositor source. The fix has to land in `CTMControl.cpp`.

## The patch

**File:** `src/protocols/CTMControl.cpp`, the `setCommit` lambda.

**Current:**

```cpp
    m_resource->setCommit([this](CHyprlandCtmControlManagerV1* r) {
        if (m_blocked)
            return;

        LOGM(Log::DEBUG, "Committing ctms to outputs");

        for (auto& m : State::monitorState()->monitors()) {
            if (!m_ctms.contains(m->m_name)) {
                PROTO::ctm->setCTM(m, Mat3x3::identity());
                continue;
            }

            PROTO::ctm->setCTM(m, m_ctms.at(m->m_name));
        }
    });
```

**Patched:**

```cpp
    m_resource->setCommit([this](CHyprlandCtmControlManagerV1* r) {
        if (m_blocked)
            return;

        LOGM(Log::DEBUG, "Committing ctms to outputs");

        for (auto& m : State::monitorState()->monitors()) {
            Mat3x3 ctm = Mat3x3::identity();
            if (m_ctms.contains(m->m_name))
                ctm = m_ctms.at(m->m_name);
            else if (m->m_mirrorOf && m_ctms.contains(m->m_mirrorOf->m_name))
                ctm = m_ctms.at(m->m_mirrorOf->m_name);
            PROTO::ctm->setCTM(m, ctm);
        }
    });
```

Field names verified against the `v0.56.2` tag:
- `m_ctms` — `std::unordered_map<std::string, Mat3x3>`, keyed by monitor name.
- `State::monitorState()->monitors()` — iteration over all monitors (incl. mirrored ones).
- `m->m_name` — monitor name (`eDP-1`, `HDMI-A-1`).
- `m->m_mirrorOf` — `PHLMONITORREF`; supports `operator bool` (aliveness) + `operator->`, same pattern the existing `setCTM` lambda uses (`if (!monitor || ...)`, `monitor->setCTM(...)`).

Minimal, surgical, protocol-compliant (a CTM is still committed for every output; only the *value* chosen for a mirroring monitor changes from `identity` to its source's CTM). No new config keys, no protocol bump.

## Build & install (update-surviving)

Strategy: clone the Hyprland source at the **exact installed tag**, apply the patch, build to a local dir, and launch the built binary from `~/projects/Hyprland/build/Hyprland` instead of `/usr/bin/Hyprland`. The system `hyprland` package stays untouched, so `pacman -Syu` never overwrites the patch — only the user chooses when to re-pin a new tag and rebuild.

```bash
# 1. Build deps (everything else — aquamarine, hyprutils, hyprcursor,
#    hyprgraphics, hyprlang, hyprwire, hyprwayland-scanner, mesa, libdrm,
#    libinput, wayland, pixman, glslang, tomlplusplus, re2, muparser, lcms2 —
#    is already pulled in by the installed `hyprland 0.56.2-1` runtime deps).
sudo pacman -S --needed base-devel cmake ninja git

# 2. Clone at the exact installed tag (ABI matches system libs).
git clone --recursive -b v0.56.2 https://github.com/hyprwm/Hyprland ~/projects/Hyprland
cd ~/projects/Hyprland

# 3. Apply the patch (edit src/protocols/CTMControl.cpp setCommit lambda — see above).

# 4. Configure + build. Output: ~/projects/Hyprland/build/Hyprland
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j"$(nproc)"
```

Then point the session at the patched binary. In `~/.bash_profile`, prepend the build dir to `PATH` **before** `/usr/bin`:

```bash
# ~/.bash_profile (prepend)
[ -d "$HOME/projects/Hyprland/build" ] && export PATH="$HOME/projects/Hyprland/build:$PATH"
```

Log out of the Hyprland session (return to TTY1), log back in, start `Hyprland` — it now resolves to the patched binary. The system `/usr/bin/Hyprland` remains as fallback.

> Why this survives updates: `~/projects/` is user data; `pacman` never touches it. The `.bash_profile` line is user data too. `pacman -Syu` can bump the system `hyprland` package all it likes — the patched binary in `~/projects/Hyprland/build/Hyprland` is unaffected until the user deliberately re-pins a new tag (see **Update chore**).

## Verify

```bash
# In the patched session:
hyprsunset --verbose -t 3000       # still logs "Found 1 output(s)" — that's fine;
                                   # the propagation is server-side now.

# Toggle and watch BOTH screens:
hyprctl hyprsunset temperature 3000   # both eDP-1 + HDMI-A-1 go warm
hyprctl hyprsunset identity           # both go back to neutral
```

Open a white window (or a terminal with a light background) on both screens — both must shift warm/neutral together. Before the patch, only `eDP-1` shifted; `HDMI-A-1` stayed neutral.

## Rollback

Comment the `PATH` prepend in `~/.bash_profile`, log out, log back in, start `Hyprland` → back to the system binary. No files removed, nothing to undo. The patched source tree stays in `~/projects/Hyprland` for the next attempt.

## Update chore (only when you choose)

Rebuild only to track a new Hyprland release — never forced by `pacman`:

```bash
cd ~/projects/Hyprland
git fetch --tags
git checkout v0.57.x                       # or whichever tag you want
git submodule update --init --recursive
# re-apply the patch to src/protocols/CTMControl.cpp if the file changed upstream
cmake --build build -j"$(nproc)"           # reconfigure too if CMakeLists changed
```

Restart the session to pick up the rebuilt binary.

## Upstream PR (later)

When ready to push this upstream so it ships in the package and the local build can be retired:

```bash
cd ~/projects/Hyprland
git remote add fork git@github.com:<you>/Hyprland.git   # your fork
git checkout -b fix/ctm-mirror-propagation
git add src/protocols/CTMControl.cpp
git commit -m "ctm: propagate source CTM to mirrored monitors on commit"
git push -u fork fix/ctm-mirror-propagation
```

Open the PR against `hyprwm/Hyprland`. Suggested body:

- **What:** In `CTMControl.cpp`'s commit handler, when a monitor has no CTM set directly but is mirroring a monitor that does, apply the source's CTM to the mirror too.
- **Why:** Mirrors are meant to visually match their source. Today the warm filter (hyprsunset, `hyprland-ctm-control-v1`) lands only on the source monitor; mirrored outputs get `identity` because the source is the only `wl_output` advertised to clients. Refs `hyprwm/hyprsunset#85`.
- **Scope:** ~6 lines, no protocol change, no config keys, no behavior change for non-mirrored setups.
- **Test:** mirror one monitor onto another, run `hyprsunset -t 3000`, confirm both warm; `hyprctl hyprsunset identity`, confirm both reset.

Once merged and shipped in a tagged release (e.g. `0.57.x`), revert the `PATH` prepend in `~/.bash_profile` and use the package again — mirroring restored with the warm filter on both, zero local maintenance.

## Alternatives considered (reference)

| Fix | Where | Survives `pacman -Syu`? | Tradeoff |
| --- | --- | --- | --- |
| **A (chosen)** — source patch + local build | `~/projects/Hyprland/build/Hyprland` | yes (until *you* re-pin) | Rebuild chore on new releases; real fix; PR-worthy |
| **B** — config: `mirror` → `position = "auto-up"` in `modules/monitors.lua` | `~/.config/hypr/` (user data) | yes | Instant; both outputs independent so both get the CTM; **loses mirroring** (external becomes a 2nd workspace) |
| **C** — external monitor's OSD night-light | monitor firmware | yes (independent of all software) | Keeps mirror; manual on the monitor; no time-based auto-switch on the external |

## Risk

The patched binary in `~/projects/Hyprland/build/Hyprland` links system shared libs (`libaquamarine.so`, `libhyprutils.so`, …). If a future `pacman -Syu` bumps one of those with an ABI break, the patched binary may fail to start at next login. Mitigation: the system `/usr/bin/Hyprland` is untouched and remains the TTY fallback — comment the `PATH` prepend and start the system binary. Worst case is "rebuild before next login," never a bricked session.
