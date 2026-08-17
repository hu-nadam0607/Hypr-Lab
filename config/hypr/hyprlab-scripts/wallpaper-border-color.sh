#!/usr/bin/env bash
set -euo pipefail

image="${1:-}"

[[ -f "$image" ]] || exit 0

color="$(
    magick "$image" \
        -resize 96x96 \
        -colors 24 \
        -format %c histogram:info:- |
    grep -oE '#[0-9A-Fa-f]{6}' |
    while read -r hex; do
        r=$((16#${hex:1:2}))
        g=$((16#${hex:3:2}))
        b=$((16#${hex:5:2}))

        max=$r
        (( g > max )) && max=$g
        (( b > max )) && max=$b

        min=$r
        (( g < min )) && min=$g
        (( b < min )) && min=$b

        chroma=$((max - min))
        brightness=$(( (r * 299 + g * 587 + b * 114) / 1000 ))

        # Csak a használhatatlan szélsőségeket dobjuk ki.
        (( brightness < 30 )) && continue
        (( brightness > 240 )) && continue

        # A LEGTELÍTETTEBB / legélénkebb szín nyer.
        printf '%d %s\n' "$chroma" "$hex"
    done |
    sort -nr |
    head -n1 |
    awk '{print $2}'
)"

if [[ -z "$color" ]]; then
    color="$(
        magick "$image" \
            -resize 96x96 \
            -colors 8 \
            -format %c histogram:info:- |
        sort -nr |
        grep -oE '#[0-9A-Fa-f]{6}' |
        while read -r hex; do
            r=$((16#${hex:1:2}))
            g=$((16#${hex:3:2}))
            b=$((16#${hex:5:2}))

            brightness=$(( (r * 299 + g * 587 + b * 114) / 1000 ))

            if (( brightness >= 55 && brightness <= 210 )); then
                echo "$hex"
                break
            fi
        done
    )"
fi

[[ -n "$color" ]] || color="#68787D"

hex="${color#\#}"

mkdir -p "$HOME/.cache/hypr-lab"
printf '%s\n' "$hex" > "$HOME/.cache/hypr-lab/border-color"

hyprctl eval "
hl.config({
    general = {
        col = {
            active_border = \"rgba(${hex}dd)\",
            inactive_border = \"rgba(${hex}44)\"
        }
    }
})
"