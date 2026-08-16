#!/usr/bin/env bash

sleep 1

dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland
systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

killall -q xdg-desktop-portal-gnome

systemctl --user stop xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
sleep 0.5

systemctl --user start xdg-desktop-portal-hyprland
systemctl --user start xdg-desktop-portal
