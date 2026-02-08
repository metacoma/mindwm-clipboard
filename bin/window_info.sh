#!/usr/bin/env bash
set -euo pipefail

WIN_ID=$(xdotool getactivewindow)

xprop_val() {
  xprop -id "$WIN_ID" "$1" 2>/dev/null \
    | sed -E 's/^[^=]+= *//'
}

clean() {
  tr -d '\n"'
}

# generic comma-separated xprop -> JSON array
csv_array() {
  tr -d '"' \
  | tr ',' '\n' \
  | sed 's/^ *//;s/ *$//' \
  | sed '/^$/d' \
  | jq -R . \
  | jq -s .
}

wm_class_array() {
  xprop_val WM_CLASS | csv_array
}

state_array() {
  xprop_val _NET_WM_STATE | csv_array
}

geometry_json() {
  local wid="${1:?window id required}"

  local x="" y="" w="" h="" screen=""

  while IFS='=' read -r k v; do
    case "$k" in
      X)      x="$v" ;;
      Y)      y="$v" ;;
      WIDTH)  w="$v" ;;
      HEIGHT) h="$v" ;;
      SCREEN) screen="$v" ;;
      *) : ;; # ignore WINDOW=..., etc
    esac
  done < <(xdotool getwindowgeometry --shell "$wid" 2>/dev/null || true)

  jq -c -n \
    --argjson x      "${x:-0}" \
    --argjson y      "${y:-0}" \
    --argjson width  "${w:-0}" \
    --argjson height "${h:-0}" \
    --argjson screen "${screen:-0}" \
    '{x:$x, y:$y, width:$width, height:$height, screen:$screen}'
}

pid_json() {
  local wid="${1:?window id required}"

  local pid=""
  pid=$(xprop -id "$wid" _NET_WM_PID 2>/dev/null | awk '{print $NF}' || true)

  if [[ -z "$pid" || ! "$pid" =~ ^[0-9]+$ ]]; then
    echo "null"
    return
  fi

  jq -c -n --argjson pid "$pid" '$pid'
}

process_json() {
  local pid="${1:-null}"

  [[ -z "$pid" || "$pid" == "null" ]] && echo "null" && return
  [[ ! "$pid" =~ ^[0-9]+$ ]] && echo "null" && return
  [[ ! -r "/proc/$pid/cmdline" ]] && echo "null" && return

  local exe cmdline cwd
  exe=$(readlink -f "/proc/$pid/exe" 2>/dev/null || true)
  cmdline=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || true)
  cwd=$(readlink -f "/proc/$pid/cwd" 2>/dev/null || true)

  jq -c -n \
    --arg exe "$exe" \
    --arg cmdline "$cmdline" \
    --arg cwd "$cwd" \
    '{exe:$exe, cmdline:$cmdline, cwd:$cwd}'
}

PID_JSON="$(pid_json "$WIN_ID")"
PROCESS_JSON="$(process_json "$PID_JSON")"

jq -n \
  --arg window_id "$WIN_ID" \
  --arg wm_name "$(xprop_val WM_NAME | clean)" \
  --arg net_wm_name "$(xprop_val _NET_WM_NAME | clean)" \
  --arg type "$(xprop_val _NET_WM_WINDOW_TYPE | clean)" \
  --argjson wm_class "$(wm_class_array)" \
  --argjson state "$(state_array)" \
  --argjson geometry "$(geometry_json "$WIN_ID")" \
  --argjson pid "$PID_JSON" \
  --argjson process "$PROCESS_JSON" \
'
{
  window_id: $window_id,
  wm_class: $wm_class,
  wm_name: $wm_name,
  net_wm_name: $net_wm_name,
  pid: $pid,
  process: $process,
  geometry: $geometry,
  state: $state,
  type: $type
}
'
