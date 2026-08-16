#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprlab-settings"
STATE="${STATE_DIR}/state.conf"
MONITOR_STATE="${STATE_DIR}/monitors.json"
mkdir -p "$STATE_DIR"

defaults() {
cat <<'EOF'
BORDER_SIZE=2
ROUNDING=17
ACTIVE_OPACITY=0.80
INACTIVE_OPACITY=0.70
SHADOW=1
BLUR=1
BLUR_SIZE=4
BLUR_PASSES=3
ANIMATIONS=1
GAPS_IN=5
GAPS_OUT=10
EOF
}

[[ -f "$STATE" ]] || defaults > "$STATE"
[[ -f "$MONITOR_STATE" ]] || printf '[]\n' > "$MONITOR_STATE"

lua_bool() {
    [[ "$1" == "1" || "$1" == "true" ]] && printf 'true' || printf 'false'
}

lua_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    printf '%s' "$s"
}

eval_lua() {
    hyprctl eval "$1" >/dev/null
}

save_key() {
    local key="$1" val="$2"
    if grep -q "^${key}=" "$STATE"; then
        sed -i "s|^${key}=.*|${key}=${val}|" "$STATE"
    else
        printf '%s=%s\n' "$key" "$val" >> "$STATE"
    fi
}

apply_one() {
    local key="$1" val="$2"
    case "$key" in
        BORDER_SIZE)
            eval_lua "hl.config({ general = { border_size = ${val} } })"
            ;;
        ROUNDING)
            eval_lua "hl.config({ decoration = { rounding = ${val} } })"
            ;;
        ACTIVE_OPACITY)
            eval_lua "hl.config({ decoration = { active_opacity = ${val} } })"
            ;;
        INACTIVE_OPACITY)
            eval_lua "hl.config({ decoration = { inactive_opacity = ${val} } })"
            ;;
        SHADOW)
            eval_lua "hl.config({ decoration = { shadow = { enabled = $(lua_bool "$val") } } })"
            ;;
        BLUR)
            eval_lua "hl.config({ decoration = { blur = { enabled = $(lua_bool "$val") } } })"
            ;;
        BLUR_SIZE)
            eval_lua "hl.config({ decoration = { blur = { size = ${val} } } })"
            ;;
        BLUR_PASSES)
            eval_lua "hl.config({ decoration = { blur = { passes = ${val} } } })"
            ;;
        ANIMATIONS)
            eval_lua "hl.config({ animations = { enabled = $(lua_bool "$val") } })"
            ;;
        GAPS_IN)
            eval_lua "hl.config({ general = { gaps_in = ${val} } })"
            ;;
        GAPS_OUT)
            eval_lua "hl.config({ general = { gaps_out = ${val} } })"
            ;;
    esac
}

monitor_snapshot() {
    hyprctl monitors all -j
}

save_monitor() {
    local name="$1" mode="$2" position="$3" scale="$4"
    local tmp
    tmp="$(mktemp)"
    jq \
      --arg name "$name" \
      --arg mode "$mode" \
      --arg position "$position" \
      --argjson scale "$scale" \
      '
      (map(select(.name != $name))) +
      [{name:$name, mode:$mode, position:$position, scale:$scale}]
      ' "$MONITOR_STATE" > "$tmp"
    mv "$tmp" "$MONITOR_STATE"
}

apply_monitor() {
    local name="$1" mode="$2" position="$3" scale="$4"
    mode="${mode%Hz}"

    local n m p
    n="$(lua_escape "$name")"
    m="$(lua_escape "$mode")"
    p="$(lua_escape "$position")"

    eval_lua "hl.monitor({ output = \"${n}\", mode = \"${m}\", position = \"${p}\", scale = ${scale} })"
}

current_monitor_position() {
    local name="$1"
    hyprctl monitors all -j | jq -r --arg n "$name" '
      .[] | select(.name == $n) |
      ((.x // 0)|tostring) + "x" + ((.y // 0)|tostring)
    ' | head -n1
}

case "${1:-}" in
    dump)
        cat "$STATE"
        ;;

    set)
        key="${2:?key}"
        val="${3:?value}"
        save_key "$key" "$val"
        apply_one "$key" "$val"
        ;;

    apply)
        while IFS='=' read -r key val; do
            [[ -z "$key" || "$key" == \#* ]] && continue
            apply_one "$key" "$val" || true
        done < "$STATE"

        jq -c '.[]' "$MONITOR_STATE" | while IFS= read -r row; do
            name="$(jq -r '.name' <<<"$row")"
            mode="$(jq -r '.mode' <<<"$row")"
            position="$(jq -r '.position' <<<"$row")"
            scale="$(jq -r '.scale' <<<"$row")"
            apply_monitor "$name" "$mode" "$position" "$scale" || true
        done
        ;;

    monitors)
        monitor_snapshot
        ;;

    monitor-mode)
        name="${2:?name}"
        mode="${3:?mode}"
        scale="${4:-1}"
        position="${5:-$(current_monitor_position "$name")}"
        [[ -n "$position" ]] || position="auto"
        apply_monitor "$name" "$mode" "$position" "$scale"
        save_monitor "$name" "${mode%Hz}" "$position" "$scale"
        ;;

    monitor-scale)
        name="${2:?name}"
        scale="${3:?scale}"

        row="$(hyprctl monitors all -j | jq -c --arg n "$name" '.[] | select(.name == $n)' | head -n1)"
        [[ -n "$row" ]] || { echo "Monitor not found: $name" >&2; exit 1; }

        width="$(jq -r '.width // 0' <<<"$row")"
        height="$(jq -r '.height // 0' <<<"$row")"
        refresh="$(jq -r '.refreshRate // 60' <<<"$row")"
        x="$(jq -r '.x // 0' <<<"$row")"
        y="$(jq -r '.y // 0' <<<"$row")"

        mode="${width}x${height}@${refresh}"
        position="${x}x${y}"

        apply_monitor "$name" "$mode" "$position" "$scale"
        save_monitor "$name" "$mode" "$position" "$scale"
        ;;

    *)
        echo "usage: $0 dump|set KEY VALUE|apply|monitors|monitor-mode NAME MODE [SCALE] [POSITION]|monitor-scale NAME SCALE" >&2
        exit 2
        ;;
esac
