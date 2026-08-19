#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${CALCULATOR:-}" ]] && command -v "${CALCULATOR%% *}" >/dev/null 2>&1; then
    exec sh -lc "$CALCULATOR"
fi

for app in gnome-calculator kcalc qalculate-gtk galculator mate-calc; do
    if command -v "$app" >/dev/null 2>&1; then
        exec "$app"
    fi
done

notify-send "Hypr-Lab" "No calculator application found."
