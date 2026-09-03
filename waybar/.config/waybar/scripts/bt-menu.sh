#!/bin/sh
# Bluetooth fuzzel menu: power toggle, connect/disconnect paired devices,
# scan & pair via bluetoothctl TUI fallback.
#
# Entry points:
#   bt-menu.sh           -> open the menu
#   bt-menu.sh toggle     -> quick power toggle (right-click)

set -u

notify() { command notify-send "$@" 2>/dev/null || true; }

power_state() {
    bluetoothctl show 2>/dev/null | awk '/^\s*Powered:/{print $2}'
}

if [ "${1:-}" = "toggle" ]; then
    st=$(power_state)
    if [ "$st" = "yes" ]; then
        bluetoothctl power off >/dev/null 2>&1
        notify "Bluetooth" "Power OFF"
    else
        bluetoothctl power on >/dev/null 2>&1
        notify "Bluetooth" "Power ON"
    fi
    exit 0
fi

cur=$(power_state)
[ "$cur" = "yes" ] && cur="ON" || cur="OFF"
entries="Toggle power  (currently $cur)"

# Append paired devices with their connected state.
bluetoothctl devices Paired 2>/dev/null | while IFS= read -r line; do
    # line: "Device AA:BB:CC:DD:EE:FF Name"
    set -- $line
    mac=$2
    shift 2
    name=$*
    connected=$(bluetoothctl info "$mac" 2>/dev/null | awk '/^\s*Connected:/{print $2}')
    [ "$connected" = "yes" ] && suffix="  [connected]" || suffix="  [disconnected]"
    printf '%s\n' "$mac  $name$suffix"
done >>/tmp/bt-menu.$$

entries="$entries
$(cat /tmp/bt-menu.$$ 2>/dev/null)
Scan & pair (TUI)..."
rm -f /tmp/bt-menu.$$

sel=$(printf '%s\n' "$entries" | fuzzel --prompt="BT" -d 2>/dev/null)
[ -z "$sel" ] && exit 0

case "$sel" in
    "Toggle power"*)
        st=$(power_state)
        if [ "$st" = "yes" ]; then
            bluetoothctl power off >/dev/null 2>&1
            notify "Bluetooth" "Power OFF"
        else
            bluetoothctl power on >/dev/null 2>&1
            notify "Bluetooth" "Power ON"
        fi
        ;;
    "Scan & pair"*)
        kitty -e bluetoothctl
        ;;
    *)
        # Device line: "MAC  Name  [state]"
        mac=${sel%% *}
        connected=$(bluetoothctl info "$mac" 2>/dev/null | awk '/^\s*Connected:/{print $2}')
        if [ "$connected" = "yes" ]; then
            bluetoothctl disconnect "$mac" >/dev/null 2>&1 \
                && notify "Bluetooth" "Disconnected" \
                || notify -u critical "Bluetooth" "Disconnect failed"
        else
            bluetoothctl connect "$mac" >/dev/null 2>&1 \
                && notify "Bluetooth" "Connected" \
                || notify -u critical "Bluetooth" "Connect failed (pair first?)"
        fi
        ;;
esac
