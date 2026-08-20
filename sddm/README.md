# Custom SDDM Theme

The `yuki-wallpaper` theme uses the Nagato wallpaper and profile image from
`wallpaper/` and is installed manually because SDDM themes live under
`/usr/share` and require root permissions.

Install the theme (run from the repo root — `pkexec` runs with
`$PWD = /root`, so the `$PWD` prefix keeps paths valid):

```bash
pkexec install -d -m 755 /usr/share/sddm/themes/yuki-wallpaper
pkexec install -m 644 "$PWD"/sddm/yuki-wallpaper/* /usr/share/sddm/themes/yuki-wallpaper/
pkexec install -m 644 "$PWD"/sddm/99-yuki-wallpaper.conf /etc/sddm.conf.d/99-yuki-wallpaper.conf
```

The login screen uses `SFMono Nerd Font`, `background_nagato.jpg`, and
`profile_nagato.jpg`.
