# Hypr-Files v0.1.0

Hypr-Lab saját Quickshell/QML fájlkezelője.

## Könyvtár

Másold ezt a teljes mappát ide:

```text
~/.config/quickshell/files/
```

A struktúra:

```text
files/
├── assets/
│   └── hypr-lab-files.svg
├── components/
│   ├── AdaptiveAccent.qml
│   ├── FileGridItem.qml
│   ├── FileListRow.qml
│   └── SidebarItem.qml
├── scripts/
│   ├── hypr-files-backend.py
│   ├── hypr-files-register.sh
│   └── hypr-files.sh
├── README.md
└── shell.qml
```

## Első indítás

```bash
chmod +x ~/.config/quickshell/files/scripts/hypr-files.sh
chmod +x ~/.config/quickshell/files/scripts/hypr-files-register.sh
chmod +x ~/.config/quickshell/files/scripts/hypr-files-backend.py

~/.config/quickshell/files/scripts/hypr-files.sh
```

Tetszőleges könyvtárral:

```bash
~/.config/quickshell/files/scripts/hypr-files.sh "$HOME/Képek"
```

## App Launcher integráció

```bash
~/.config/quickshell/files/scripts/hypr-files-register.sh
```

Ez létrehozza:

```text
~/.local/share/applications/hypr-lab-files.desktop
```

Ha teszt után a Hypr-Files legyen az alapértelmezett mappakezelő:

```bash
~/.config/quickshell/files/scripts/hypr-files-register.sh --set-default
```

## v0.1.0 funkciók

- saját Hypr-Lab square / zero-radius UI
- dinamikus Hypr-Lab accent szín
- `FloatingWindow`, ugyanazon az elven, mint a Hypr-Viewer
- Home / XDG user folder / device sidebar
- grid és list nézet
- képthumbnail gridben
- név szerinti live keresés
- név / módosítás / méret / típus szerinti rendezés
- rejtett fájlok Ctrl+H-val
- Back / Forward / Up / Home
- kézzel szerkeszthető útvonal
- egy- és többes kijelölés Ctrl+kattal
- Ctrl+A
- fájl/mappa megnyitás
- Open With alkalmazásválasztó
- Open in Terminal (Ghostty elsődlegesen)
- New Folder
- Rename
- Cut / Copy / Paste
- Move to Trash (`gio trash`)
- permanent delete külön megerősítéssel
- jobb oldali Details panel
- jobb klikkes context menu
- billentyűbindek: Ctrl+L, Ctrl+F, Ctrl+H, Ctrl+A/C/X/V, F2, Delete, Shift+Delete, Alt+Left/Right/Up, Backspace, Ctrl+Shift+N

## Megjegyzés

A drag-and-drop nincs bekapcsolva ebben az első tesztbuildben. A Quickshell/Qt DnD viselkedését külön érdemes stabilizálni, mielőtt valódi fájlműveletet kötünk rá.

### v0.1.0 hotfix 1
Fixed Quickshell delegate bindings for JS-array-backed models (`modelData` was undefined on the tested runtime).

## v0.1.0 hotfix 10 – native Hyprland floating launch

Hypr-Files is launched through Hyprland's `hl.dsp.exec_cmd()` with static
`float = true` and `center = true` rules. The window therefore starts floating
and centered immediately instead of being tiled first and converted after map.

## Hotfix 12

- Replaced generic File System/mnt sidebar entries with mounted physical SSD/HDD/NVMe devices detected from `lsblk`.
- Added persistent **Favorites**. Drag folders from the file view onto Favorites; right-click a favorite to remove it.
- Added a custom center-view vertical scroll indicator with always-visible up/down arrows and a fading animated track/thumb shown while scrolling.

### Hotfix 14
Favorites drag-and-drop now uses Qt Quick's `Drag.Automatic` new-style DnD path,
with a folder drag image and reliable `DropArea.onDropped` handling.

## Hotfix 16

- Sidebar now has always-visible up/down controls and a fading scroll track when its content exceeds the available height.
- `Ctrl+T` opens a new tab at `/home`.
- `Ctrl+W` closes the tab under the mouse cursor, or the active tab when no tab is hovered.
- Each tab keeps its own path and back/forward history.
- Files and folders can be dragged onto another tab using the Hypr-Files in-window drag layer.
- Dropping onto another tab opens a Copy / Move / Cancel confirmation dialog; Cancel leaves the filesystem unchanged.

## Hotfix 18

- Copy, move, Move to Trash and permanent delete now stream live progress to the UI.
- The bottom status bar shows operation name, current item, an animated progress bar and numeric percentage.
- `hypr-files-register.sh --set-default` sets `inode/directory` to `hypr-lab-files.desktop` and installs a persistent Hyprland `SUPER+E` binding through `~/.config/hypr/hyprlab-files.conf`.
- The generated Hyprland fragment first unbinds any previous `SUPER+E` action (for example Nautilus), then binds Hypr-Files, and reloads Hyprland when a session is active.

## Hotfix 20

- Added an **EXTERNAL DEVICES** sidebar section for physically attached USB block devices only.
- USB disks expose their partitions separately with **MOUNT / UNMOUNT** actions.
- **EJECT** performs safe removal by unmounting mounted child partitions and powering off the USB disk through `udisksctl`.
- External device state refreshes automatically while Hypr-Files is open.
- Added keyboard navigation with the cursor keys; Grid view uses all four directions, while List view uses Up/Down for rows, Left for parent folder, and Right to open the selected entry.

## Hotfix 21
- External USB device sidebar auto-refreshes every 2 seconds while Hypr-Files is open.
- Copy/move now preflights destination name conflicts and asks before changing anything.
- Conflict dialog offers Overwrite, Keep both (automatic renamed copy), or Cancel.
