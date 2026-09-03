#!/bin/sh
# List visible Wi-Fi networks via nmcli, pick one with fuzzel, connect.
# Falls back to nmtui (in kitty) when connection needs a password or fails.

set -u

notify() { command notify-send "$@" 2>/dev/null || true; }

# Build menu: "SIGNAL SSID" sorted by signal desc, deduped by SSID.
# nmcli -t escapes literal ':' in SSID as '\:' so field split on first ':' is safe.
menu=$(
    nmcli -t -f SIGNAL,SSID device wifi list --rescan auto 2>/dev/null \
    | awk -F: '
        {
            sig = $1
            sub(/^\\:/, ":", $0)            # unescape leading escaped colon in SSID
            rest = substr($0, length($1) + 2)
            if (rest == "" || rest == "*") next
            if (!seen[rest] || sig > best[rest]) {
                seen[rest] = 1
                best[rest] = sig
                line[rest] = sprintf("%3d  %s", sig, rest)
            }
        }
        END { for (r in line) print line[r] }
      ' \
    | sort -rn
)

[ -z "$menu" ] && {
    notify -u critical "Wi-Fi" "No networks found"
    exit 1
}

sel=$(printf '%s\n' "$menu" | fuzzel --prompt="Wi-Fi" -d 2>/dev/null)
[ -z "$sel" ] && exit 0

# Strip leading "SIG  " prefix to recover the SSID (which may contain spaces).
ssid=${sel#*  }

# Known network: connects silently. New network: nmcli needs a password agent.
if ! nmcli device wifi connect "$ssid" 2>/dev/null; then
    notify -u normal "Wi-Fi" "Connecting to '$ssid' needs a password"
    kitty -e nmtui
else
    notify -u normal "Wi-Fi" "Connected to '$ssid'"
fi
