#!/usr/bin/env bash
# hyprshell-watchdog.sh — auto-recover from the hyprshell freeze bug
# (Alt+Tab + Q on the last window leaves the switcher layer open with 0
#  clients, the keyboard grab never releases, and the session appears frozen).
#
# The Hyprland compositor keeps running during the freeze — hyprctl bypasses
# the layer-shell keyboard grab (direct socket) — so this watchdog can detect
# the stuck state and release it.
#
# Detection: hyprshell_switch layer present AND 0 clients on the focused monitor
#           for > STUCK_THRESHOLD seconds.
# Recovery:  1) graceful:  hyprshell socat CloseSwitch
#            2) escalate: pkill -TERM hyprshell + restart daemon (cooldown+capped)
#
# Run via Hyprland autostart: nohup ... hyprshell-watchdog.sh & disown
set -u

HYPRSHELL_BIN="${HYPRSHELL_BIN:-$HOME/.local/bin/hyprshell}"
HYPRSHELL_CFG="${HYPRSHELL_CFG:-$HOME/.config/hyprshell/config.json5}"
POLL_MS="${POLL_MS:-500}"
STUCK_THRESHOLD_MS="${STUCK_THRESHOLD_MS:-1500}"
RESTART_COOLDOWN_MS="${RESTART_COOLDOWN_MS:-5000}"
MAX_RESTARTS="${MAX_RESTARTS:-5}"
RESTART_WINDOW_MS="${RESTART_WINDOW_MS:-60000}"

stuck_since=""
restart_count=0
restart_window_start=""
last_restart=""

is_switcher_open() {
  hyprctl layers -j 2>/dev/null | jq -e '
    [.[] | .levels | to_entries[] | .value[]?
      | select(.namespace == "hyprshell_switch")] | length > 0
  ' >/dev/null 2>&1
}

clients_on_focused_monitor() {
  # Print count of clients on the currently focused monitor.
  local mon_id
  mon_id=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .id' 2>/dev/null)
  if [[ -z "$mon_id" ]]; then
    echo "0"
    return
  fi
  hyprctl clients -j 2>/dev/null | jq -r --argjson m "$mon_id" '
    [.[] | select(.monitor == $m)] | length
  ' 2>/dev/null
}

now_ms() { date +%s%3N; }

within_window() {
  # True if $2 (now) is within the restart window started at $1.
  local start="$1" now="$2"
  [[ -n "$start" ]] || return 1
  (( now - start < RESTART_WINDOW_MS ))
}

do_graceful_close() {
  "$HYPRSHELL_BIN" socat '{"CloseSwitch":{"switch":true}}' >/dev/null 2>&1
}

do_restart() {
  # Cap restarts to avoid a spin loop if something is fundamentally broken.
  local now
  now=$(now_ms)
  if [[ -z "$restart_window_start" ]] || ! within_window "$restart_window_start" "$now"; then
    restart_window_start="$now"
    restart_count=0
  fi
  if (( restart_count >= MAX_RESTARTS )); then
    printf 'hyprshell-watchdog: max restarts (%d) hit within %ds — leaving hyprshell down; investigate manually\n' \
      "$MAX_RESTARTS" "$((RESTART_WINDOW_MS/1000))" >&2
    return 1
  fi
  if [[ -n "$last_restart" ]] && (( now - last_restart < RESTART_COOLDOWN_MS )); then
    return 1
  fi
  printf 'hyprshell-watchdog: graceful close failed — restarting hyprshell (restart %d/%d)\n' \
    "$((restart_count+1))" "$MAX_RESTARTS" >&2
  pkill -TERM -f 'hyprshell .* run' >/dev/null 2>&1
  sleep 0.3
  # Ensure the old process is really gone before relaunching.
  if pgrep -f 'hyprshell .* run' >/dev/null 2>&1; then
    pkill -KILL -f 'hyprshell .* run' >/dev/null 2>&1
    sleep 0.2
  fi
  nohup "$HYPRSHELL_BIN" -c "$HYPRSHELL_CFG" run >/dev/null 2>&1 &
  disown
  last_restart="$now"
  restart_count=$((restart_count+1))
}

printf 'hyprshell-watchdog: starting (poll=%dms, threshold=%dms, max_restarts=%d/%ds)\n' \
  "$POLL_MS" "$STUCK_THRESHOLD_MS" "$MAX_RESTARTS" "$((RESTART_WINDOW_MS/1000))" >&2

while true; do
  sleep "$(awk -v ms="$POLL_MS" 'BEGIN{printf "%.3f", ms/1000}')"

  if ! is_switcher_open; then
    stuck_since=""
    continue
  fi

  # Switcher layer is present — check client count on the focused monitor.
  count=$(clients_on_focused_monitor)
  if [[ "$count" != "0" ]]; then
    stuck_since=""
    continue
  fi

  # Stuck condition: switcher open + 0 clients. Track how long it persists.
  if [[ -z "$stuck_since" ]]; then
    stuck_since=$(now_ms)
    continue
  fi
  now=$(now_ms)
  if (( now - stuck_since < STUCK_THRESHOLD_MS )); then
    continue
  fi

  printf 'hyprshell-watchdog: stuck state detected (switcher open, 0 clients, %dms) — attempting graceful close\n' \
    "$((now - stuck_since))" >&2

  do_graceful_close
  sleep 0.8

  if ! is_switcher_open; then
    printf 'hyprshell-watchdog: graceful close succeeded — switcher released\n' >&2
    stuck_since=""
    continue
  fi

  printf 'hyprshell-watchdog: graceful close did not release — escalating\n' >&2
  do_restart
  stuck_since=""
done