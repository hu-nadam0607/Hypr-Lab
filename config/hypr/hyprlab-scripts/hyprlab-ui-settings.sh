#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprlab-settings"
STATE="$STATE_DIR/ui.conf"
mkdir -p "$STATE_DIR"

defaults() {
  cat <<'EOD'
WORKSPACE_COUNT=10
TOPBAR_WORKSPACES=1
TOPBAR_USB=1
TOPBAR_AUDIO=1
TOPBAR_NOTIFICATIONS=1
TOPBAR_CONTROL_CENTER=1
TOPBAR_LOCK_INDICATORS=1
TOPBAR_TRAY=1
TOPBAR_POWER=1
CENTER_VOLUME_FEEDBACK=1
CENTER_CAVA=1
CENTER_MEDIA_FEEDBACK=1
NOTIFICATION_SOUND=1
NOTIFICATION_SUMMARY=1
DND=0
NIGHT_LIGHT_AUTO=0
NIGHT_LIGHT_MANUAL=0
NIGHT_LIGHT_FROM=1200
NIGHT_LIGHT_UNTIL=420
NIGHT_LIGHT_TEMPERATURE=4500
EOD
}

ensure_state() {
  [[ -f "$STATE" ]] || defaults >"$STATE"
  while IFS='=' read -r default_key default_val; do
    [[ -n "$default_key" ]] || continue
    if ! grep -q "^${default_key}=" "$STATE"; then
      printf '%s=%s\n' "$default_key" "$default_val" >>"$STATE"
    fi
  done < <(defaults)
}

notify_runtime() {
  return 0
}

save_key() {
  local key="$1" val="$2"
  ensure_state
  if grep -q "^${key}=" "$STATE"; then
    sed -i "s|^${key}=.*|${key}=${val}|" "$STATE"
  else
    printf '%s=%s\n' "$key" "$val" >>"$STATE"
  fi
}

workspace_count() {
  ensure_state

  local count
  count="$(awk -F= '$1=="WORKSPACE_COUNT" { print $2; exit }' "$STATE")"

  [[ "$count" =~ ^[0-9]+$ ]] || count=10

  if ((count < 1)); then
    count=1
  elif ((count > 10)); then
    count=10
  fi

  printf '%s\n' "$count"
}

workspace_allowed() {
  local requested="${1:-0}"
  local count

  [[ "$requested" =~ ^[0-9]+$ ]] || return 1

  count="$(workspace_count)"

  ((requested >= 1 && requested <= count))
}

switch_workspace() {
  local requested="${1:?workspace}"

  workspace_allowed "$requested" || return 0

  hyprctl dispatch workspace "$requested" >/dev/null
}

move_to_workspace() {
  local requested="${1:?workspace}"

  workspace_allowed "$requested" || return 0

  hyprctl dispatch movetoworkspace "$requested" >/dev/null
}

ensure_state

case "${1:-dump}" in
dump)
  cat "$STATE"
  ;;
set)
  key="${2:?key}"
  value="${3:?value}"

  if [[ "$key" == "WORKSPACE_COUNT" ]]; then
    [[ "$value" =~ ^[0-9]+$ ]] || value=10

    if ((value < 1)); then
      value=1
    elif ((value > 10)); then
      value=10
    fi
  fi

  save_key "$key" "$value"
  notify_runtime

  # Numeric workspace binds are generated natively in hyprland.lua.
  # Reload only when the workspace count changes so the new bind set
  # becomes active immediately.
  if [[ "$key" == "WORKSPACE_COUNT" ]] && command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
  fi
  ;;
dnd)
  value="${2:-0}"
  save_key DND "$value"
  if [[ "$value" == "1" ]]; then
    qs ipc call notifications dndOn >/dev/null 2>&1 || true
  else
    qs ipc call notifications dndOff >/dev/null 2>&1 || true
  fi
  notify_runtime
  ;;
workspace)
  switch_workspace "${2:?workspace}"
  ;;

move-workspace)
  move_to_workspace "${2:?workspace}"
  ;;
reload-hyprland)
  hyprctl reload >/dev/null
  ;;
*)
  echo "usage: $0 dump|set KEY VALUE|dnd 0|1|workspace N|move-workspace N|reload-hyprland" >&2
  exit 2
  ;;
esac
