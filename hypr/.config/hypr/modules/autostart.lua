hl.on("hyprland.start", function()
    -- Kill leftover daemons from a previous session so the socket isn't held.
    hl.exec_cmd("pkill -f 'hyprshell-watchdog.sh'")
    hl.exec_cmd("pkill -f 'hyprshell.*run'")
    hl.exec_cmd("hyprsunset -t 3000")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("waybar")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    local home = os.getenv("HOME")
    hl.exec_cmd(home .. "/.local/bin/hyprshell -c " .. home .. "/.config/hyprshell/config.json5 run")
    -- Watchdog: auto-recover from hyprshell freeze bug (Alt+Tab+Q on last window
    -- leaves the switcher layer open with 0 clients, holding the keyboard grab).
    hl.exec_cmd(home .. "/dotfiles/script/hyprshell-watchdog.sh")
end)
