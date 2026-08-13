#!/usr/bin/env bash
# Hypr-Lab session / XDG portal initialization.
# Quickshell is deliberately started only after the Wayland/systemd environment
# has been exported and the Hyprland portal has been brought up.

set -u

# Give Hyprland a short moment to finish publishing its Wayland socket.
sleep 1

# Export the graphical-session environment for D-Bus/systemd activated apps.
dbus-update-activation-environment --systemd \
    WAYLAND_DISPLAY \
    XDG_CURRENT_DESKTOP=Hyprland \
    XDG_SESSION_TYPE=wayland 2>/dev/null || true

systemctl --user import-environment \
    WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE 2>/dev/null || true

# Avoid a stale GNOME portal competing with the Hyprland portal.
pkill -x xdg-desktop-portal-gnome 2>/dev/null || true

systemctl --user stop \
    xdg-desktop-portal \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk 2>/dev/null || true

sleep 0.5

systemctl --user start xdg-desktop-portal-hyprland 2>/dev/null || true
systemctl --user start xdg-desktop-portal 2>/dev/null || true

# Start the Hypr-Lab shell only after the graphical environment exists.
if ! pgrep -x quickshell >/dev/null 2>&1; then
    mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/hypr-lab"
    quickshell >"${XDG_STATE_HOME:-$HOME/.local/state}/hypr-lab/quickshell.log" 2>&1 &
fi
