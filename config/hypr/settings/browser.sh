#!/usr/bin/env bash
set -euo pipefail

# Prefer the desktop's configured default browser.
if command -v xdg-settings >/dev/null 2>&1 && command -v gtk-launch >/dev/null 2>&1; then
    desktop_id="$(xdg-settings get default-web-browser 2>/dev/null || true)"
    if [[ -n "${desktop_id}" ]]; then
        gtk-launch "${desktop_id}" >/dev/null 2>&1 &
        exit 0
    fi
fi

# Generic XDG fallback.
if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "about:blank" >/dev/null 2>&1 &
    exit 0
fi

# Last-resort browser discovery.
for browser in vivaldi-stable vivaldi firefox chromium google-chrome-stable brave; do
    if command -v "$browser" >/dev/null 2>&1; then
        exec "$browser"
    fi
done

echo "Hypr-Lab: no web browser detected." >&2
exit 1
