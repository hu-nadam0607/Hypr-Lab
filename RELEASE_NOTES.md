# Hypr-Lab v1.0 RC3 release notes

RC3 is the next release-safety candidate after the minimal-Arch VM installer test.

## Fixes

- **RC2 BUG #1 fixed:** `hl.exec_cmd("quickshell")` is restored in the release
  payload `hyprland.lua` autostart callback.
- Keeps the generic `__HYPRLAB_KB_LAYOUT__` payload placeholder; the installer
  replaces it with the selected layout in the installed user config.
- Retains the RC2 clean-system path: greetd + tuigreet + `start-hyprland`.
- Retains `pipewire-jack`, Bibata-Modern-Hypr-Lab and Fluent-teal-dark defaults.

## New: uninstall.sh

RC3 adds a reversible uninstall workflow.

- Records only packages that were missing and installed by Hypr-Lab.
- Can remove those packages with `pacman -Rns` via `./uninstall.sh --purge`.
- Does not remove packages that were already installed before Hypr-Lab.
- Removes Hypr-Lab-owned Bibata/Fluent theme installs when they were installed
  by Hypr-Lab.
- Restores recorded GTK/cursor settings and pre-Hypr-Lab config backups when
  available.
- Disables Hypr-Lab-managed greetd and re-enables a display manager that the
  installer previously disabled for Hypr-Lab.
- Can retain backups/state for recovery, or remove them with `--purge`.

## VM test note

VirtualBox proved useful for installer, package, greetd, Hyprland Lua and boot-path
testing, but its graphics stack is not treated as authoritative for the complete
Quickshell/Qt Wayland rendering path. Full visual validation remains a real-hardware
test.
