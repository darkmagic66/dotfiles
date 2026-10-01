---------------
---- INPUT ----
---------------
hl.config({
    input = {
        kb_layout  = "us, th",
        kb_variant = "", -- define langauge layout, path: /usr/share/X11/xkb/symbols/
        kb_model   = "", -- define keyboard layout
        kb_options = "grp:win_space_toggle",
        kb_rules   = "", 
        repeat_delay = 180,
        repeat_rate = 30,

        follow_mouse = 1,

        sensitivity = 0.8, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = true,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})

