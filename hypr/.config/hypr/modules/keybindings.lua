local v = require("modules.vars")

hl.bind("ALT + SPACE", hl.dsp.exec_cmd(v.menu))

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(v.mainMod .. " + Q", hl.dsp.exec_cmd(v.terminal))
hl.bind(v.mainMod .. " + Return", hl.dsp.exec_cmd(v.terminal))   -- Super+Enter: terminal (spec)
hl.bind(v.mainMod .. " + C", hl.dsp.window.close())
hl.bind(v.mainMod .. " + W", hl.dsp.window.close())            -- Super+W: close window (spec)
hl.bind(v.mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(v.mainMod .. " + E", hl.dsp.exec_cmd(v.fileManager))
hl.bind(v.mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(v.mainMod .. " + R", hl.dsp.exec_cmd(v.menu))
hl.bind(v.mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(v.mainMod .. " + J", hl.dsp.layout("togglesplit"))    -- dwindle only
hl.bind(v.mainMod .. " + comma", hl.dsp.exec_cmd("bash ~/dotfiles/script/settings-menu.sh"))  -- Super+, settings

-- Alt+Tab window switcher handled by hyprshell daemon (GTK4 GUI with app icons
-- + previews, like macOS). Hold ALT + tap TAB to cycle; release ALT to commit.
-- Kill: hyprshell GUI supports closing focused window via keybind (configurable
-- in `hyprshell config edit` -> Switch keybindings). Default Switch modifier is ALT.
-- No Hyprland bind here — hyprshell grabs the key combo itself when daemon is running.
-- Overview disabled (Super alone does nothing); use Alt+Tab to switch windows.

-- Layout: explicit split (dwindle) vs. default maximized (monocle).
hl.bind(v.mainMod .. " + D",       hl.dsp.exec_cmd("hyprctl eval 'hl.config({general={layout=\"dwindle\"}})'"))  -- split mode
hl.bind(v.mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("hyprctl eval 'hl.config({general={layout=\"monocle\"}})'")) -- maximized mode

-- Move focus with mainMod + arrow keys
hl.bind(v.mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(v.mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(v.mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(v.mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(v.mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(v.mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(v.mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))

-- Switch keyboard layout (us <-> th). Uses the dispatcher so the
-- activelayout IPC event fires (waybar's hyprland/language listens to it;
-- the old XKB-level "grp:win_space_toggle" toggle silently changed layouts
-- without emitting the event, so the bar never updated).
hl.bind(v.mainMod .. " + space",     hl.dsp.exec_cmd("hyprctl switchxkblayout at-translated-set-2-keyboard next"))
hl.bind(v.mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(v.mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(v.mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(v.mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(v.mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
