#!/usr/bin/env bash
set -euo pipefail

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
UI_HELPER="$CONFIG_HOME/hypr/hyprlab-scripts/hyprlab-ui-settings.sh"
STATE="$CONFIG_HOME/hypr/hyprlab-settings/ui.conf"

workspace_count() {
    local count="10"

    if [[ -f "$STATE" ]]; then
        count="$(awk -F= '$1=="WORKSPACE_COUNT" {print $2; exit}' "$STATE")"
    fi

    [[ "$count" =~ ^[0-9]+$ ]] || count=10

    if (( count < 1 )); then
        count=1
    elif (( count > 10 )); then
        count=10
    fi

    printf '%s\n' "$count"
}

active_workspace() {
    hyprctl activeworkspace -j \
        | jq -r '.id // 1'
}

clients_snapshot() {
    hyprctl clients -j
}

addresses_for_workspace() {
    local snapshot="$1"
    local workspace="$2"

    jq -r \
        --argjson ws "$workspace" \
        '.[] | select(.workspace.id == $ws) | .address' \
        <<<"$snapshot"
}

move_address() {
    local address="$1"
    local workspace="$2"

    [[ -n "$address" ]] || return 0

    if [[ "$address" != 0x* ]]; then
        address="0x${address}"
    fi

    # Hypr-Lab uses Hyprland's Lua dispatcher mode. Move the exact window
    # without following it to the destination workspace.
    hyprctl dispatch \
        "hl.dsp.window.move({ workspace = ${workspace}, follow = false, window = \"address:${address}\" })" \
        >/dev/null
}

move_addresses() {
    local addresses="$1"
    local workspace="$2"

    while IFS= read -r address; do
        [[ -n "$address" ]] || continue
        move_address "$address" "$workspace"
    done <<<"$addresses"
}

focus_workspace() {
    local workspace="$1"

    hyprctl dispatch \
        "hl.dsp.focus({ workspace = \"${workspace}\" })" \
        >/dev/null
}

set_workspace_count() {
    local count="$1"
    bash "$UI_HELPER" set WORKSPACE_COUNT "$count"
}

move_window() {
    local address="${1:?address}"
    local target="${2:?target workspace}"
    local count

    count="$(workspace_count)"

    if (( target < 1 || target > count )); then
        exit 0
    fi

    move_address "$address" "$target"
}

add_workspace() {
    local count
    count="$(workspace_count)"

    if (( count >= 10 )); then
        exit 0
    fi

    set_workspace_count "$((count + 1))"
}

close_workspace() {
    local closing="${1:?workspace}"
    local count
    local snapshot
    local active
    local new_active

    count="$(workspace_count)"

    if (( count <= 1 )); then
        exit 0
    fi

    if (( closing < 1 || closing > count )); then
        exit 0
    fi

    snapshot="$(clients_snapshot)"
    active="$(active_workspace)"
    new_active="$active"

    if (( closing == 1 )); then
        local closed_addresses
        closed_addresses="$(addresses_for_workspace "$snapshot" 1)"

        # Preserve workspace 1 windows while collapsing 2..N down by one.
        move_addresses "$closed_addresses" 99

        for ((ws = 2; ws <= count; ++ws)); do
            move_addresses \
                "$(addresses_for_workspace "$snapshot" "$ws")" \
                "$((ws - 1))"
        done

        move_addresses "$closed_addresses" 1

        if (( active == 1 || active == 2 )); then
            new_active=1
        elif (( active > 2 )); then
            new_active="$((active - 1))"
        fi
    else
        # Closed workspace windows join the nearest workspace on the left.
        move_addresses \
            "$(addresses_for_workspace "$snapshot" "$closing")" \
            "$((closing - 1))"

        for ((ws = closing + 1; ws <= count; ++ws)); do
            move_addresses \
                "$(addresses_for_workspace "$snapshot" "$ws")" \
                "$((ws - 1))"
        done

        if (( active == closing )); then
            new_active="$((closing - 1))"
        elif (( active > closing )); then
            new_active="$((active - 1))"
        fi
    fi

    set_workspace_count "$((count - 1))"
    focus_workspace "$new_active"
}

case "${1:-}" in
    move-window)
        move_window "${2:?address}" "${3:?workspace}"
        ;;

    add)
        add_workspace
        ;;

    close)
        close_workspace "${2:?workspace}"
        ;;

    *)
        echo "usage: $0 move-window ADDRESS WS | add | close WS" >&2
        exit 2
        ;;
esac
