------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
    output   = "",  -- port : DP1
    mode     = "preferred",  -- reolustion@hz : 1920*1080@144
    --position = "auto", -- extenstion mondior
    -- position = "auto-up", -- extenstion mondior
    scale    = 1, -- current * scale
    mirror = "eDP-1",
})
