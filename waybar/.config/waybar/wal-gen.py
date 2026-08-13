#!/usr/bin/env python3
"""Extract a 16-color Catppuccin-style palette from a wallpaper via ImageMagick,
emit a waybar style.css that uses it.

Slots produced (Catppuccin Mocha-compatible names):
  base mantle crust   -> 3 darkest
  text subtext        -> brightest, muted-mid
  rosewater flamingo pink mauve red maroon peach yellow
  green teal sky sapphire blue lavender -> 14 accents (vibrant mid colors)
"""
import subprocess, sys, colorsys, os, json

WALL = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/dotfiles/wallpaper/nagato.jpg")
OUT  = sys.argv[2] if len(sys.argv) > 2 else os.path.expanduser("~/.config/waybar/style.css")

def magick_colors(path, n=256, resize=256):
    cmd = ["magick", path, "-resize", f"{resize}x{resize}^",
           "-colors", str(n), "-depth", "8", "-format", "%c",
           "histogram:info:"]
    out = subprocess.check_output(cmd, text=True)
    cols = []
    for line in out.splitlines():
        line = line.strip()
        if not line or ":" not in line:
            continue
        # line like: 1234: ( 30, 32, 48) #1E1E30 srgb(30,32,48)
        if "(" not in line or "#" not in line:
            continue
        try:
            count_part = line.split(":", 1)[0].strip()
            count = int(count_part)
            hex_part = line.split("#", 1)[1].split()[0]
            r = int(hex_part[0:2], 16)
            g = int(hex_part[2:4], 16)
            b = int(hex_part[4:6], 16)
            cols.append([count, (r, g, b), hex_part])
        except Exception:
            continue
    cols.sort(key=lambda c: -c[0])
    return cols

def to_hsl(rgb):
    r, g, b = [x / 255 for x in rgb]
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    return h, l, s

def main():
    raw = magick_colors(WALL)
    if not raw:
        print("no colors extracted", file=sys.stderr); sys.exit(1)

    # Sum weights for luma sorting
    total = sum(c[0] for c in raw)
    samples = []
    for count, rgb, hx in raw:
        h, l, s = to_hsl(rgb)
        samples.append({"rgb": rgb, "hex": hx, "w": count / total,
                        "h": h, "l": l, "s": s})

    # darkest 3 → base/mantle/crust
    by_l = sorted(samples, key=lambda c: c["l"])
    base, mantle, crust = by_l[0], by_l[1], by_l[2] if len(by_l) > 2 else by_l[0]

    # lightest → text; muted mid-luma → subtext
    by_l_high = sorted(samples, key=lambda c: -c["l"])
    text = by_l_high[0]
    # subtext: high-ish luma but lower saturation
    sub_candidates = [c for c in samples if c["l"] > 0.5]
    sub_candidates.sort(key=lambda c: c["s"])  # least saturated among light
    subtext = sub_candidates[0] if sub_candidates else text

    # accents: vibrant (high sat), mid luma
    vibrant = [c for c in samples if c["s"] > 0.18 and 0.20 < c["l"] < 0.90]
    # if too few vibrant, relax saturation threshold
    if len(vibrant) < 6:
        vibrant = [c for c in samples if 0.20 < c["l"] < 0.90]
    vibrant.sort(key=lambda c: (-c["s"], -c["w"]))
    # uniq by hue distance
    def pick_unique(src, n):
        out = []
        for c in src:
            if all(abs(c["h"] - o["h"]) > 0.08 for o in out):
                out.append(c)
            if len(out) >= n:
                break
        # pad if short
        for c in src:
            if c not in out: out.append(c)
            if len(out) >= n: break
        return out[:n]

    accents = pick_unique(vibrant, 14)
    accent_names = ["rosewater", "flamingo", "pink", "mauve", "red", "maroon",
                    "peach", "yellow", "green", "teal", "sky", "sapphire",
                    "blue", "lavender"]
    palette = {name: a for name, a in zip(accent_names, accents)}

    # role assignments for waybar
    # Structural / accent colors come from the wallpaper:
    bg       = base["hex"]
    fg       = text["hex"]
    bg_dim   = mantle["hex"]

    # subtext: a muted version of fg (mix toward bg) -- guaranteed readable & dim
    def mix(h1, h2, t):
        r = round(int(h1[0:2],16)*(1-t) + int(h2[0:2],16)*t)
        g = round(int(h1[2:4],16)*(1-t) + int(h2[4:6],16)*t)
        b = round(int(h1[4:6],16)*(1-t) + int(h2[4:6],16)*t)
        return f"{r:02X}{g:02X}{b:02X}"
    fg_dim = mix(fg, bg, 0.40)  # 60% fg, 40% bg -> muted

    # active + hover from wallpaper accents:
    # active = most saturated accent; hover = lightest accent with hue variety
    accent_pool = [c for c in accents if c["s"] > 0.10]
    if accent_pool:
        active = max(accent_pool, key=lambda c: c["w"])["hex"]
        hover_cand = sorted(accent_pool, key=lambda c: -c["l"])
        hover = hover_cand[0]["hex"]
    else:
        active = fg
        hover = mix(fg, bg, 0.20)
    # ensure hover is reasonably light; if too dark, lift it
    if int(hover[0:2],16)+int(hover[2:4],16)+int(hover[4:6],16) < 250:
        hover = mix(hover, fg, 0.55)

    # Semantic status colors stay fixed (they communicate meaning, not theme):
    charging = "a6e3a1"   # green
    plugged  = "f9e2af"   # yellow
    warning  = "fab387"   # peach
    critical = "f38ba8"   # red
    urgent   = "f38ba8"   # red (workspace urgency)

    def rgba(rgb_hex, a=0.85):
        r = int(rgb_hex[0:2], 16); g = int(rgb_hex[2:4], 16); b = int(rgb_hex[4:6], 16)
        return f"rgba({r}, {g}, {b}, {a})"

    css = f"""/* Auto-generated from {WALL} */
* {{
    font-family: "MesloLGMDZ Nerd Font", "Symbols Nerd Font";
    font-size: 14px;
}}

window#waybar {{
    background: {rgba(bg, 0.85)};
    color: #{fg};
}}

/* ---- Workspaces ---- */
#workspaces button {{
    padding: 0 8px;
    color: #{fg_dim};
}}
#workspaces button.active  {{ color: #{active}; }}
#workspaces button.urgent {{ color: #{urgent}; }}
#workspaces button:hover  {{ color: #{hover}; }}

/* ---- Clock ---- */
#clock {{
    padding: 0 12px;
    color: #{fg};
}}

/* ---- Battery ---- */
#battery          {{ padding: 0 10px; color: #{fg}; }}
#battery.charging {{ color: #{charging}; }}
#battery.plugged  {{ color: #{plugged}; }}
#battery.warning  {{ color: #{warning}; }}
#battery.critical {{
    color: #{critical};
    animation-name: blink;
    animation-duration: 1s;
    animation-iteration-count: infinite;
}}

@keyframes blink {{
    50% {{ color: {rgba(bg, 1)}; }}
}}

/* palette reference (debug)
   base     #{bg}     mantle #{bg_dim}   text #{fg}     subtext #{fg_dim}
   active #{active}  urgent #{urgent}   hover #{hover}
   charge #{charging} plug #{plugged}     warn #{warning}  crit #{critical}
*/
"""

    with open(OUT, "w") as f:
        f.write(css)
    print(f"wrote {OUT}")
    print(f"base #{bg} mantle #{bg_dim} text #{fg} subtext #{fg_dim}")
    print(f"active #{active} urgent #{urgent} hover #{hover}")
    print(f"charge #{charging} plug #{plugged} warn #{warning} crit #{critical}")

if __name__ == "__main__":
    main()