# Hypr-Lab v1.0 RC3

Hypr-Lab is a Quickshell-based desktop environment-style shell for Arch Linux
and modern Hyprland Lua configurations.

The v1.0 feature set includes Control Center, Audio Control, Notification
Center, Do Not Disturb, USB Manager, App Launcher, Wallpaper Manager, Lock
Screen, Welcome Screen, media controls and Hypr-Lab Settings / Monitor tools.

## Target

- Arch Linux
- Hyprland 0.55+ Lua configuration model
- Wayland
- PipeWire + WirePlumber
- Quickshell

## What RC3 changes

RC3 continues the clean-install / release-safety pass discovered during testing on a
minimal Arch Linux VM and adds a reversible uninstall path.

- adds `pipewire-jack` explicitly so pacman does not ask which JACK provider to use;
- adds `greetd` + `tuigreet` and launches Hyprland with `start-hyprland` on a
  clean installation;
- restores the missing Quickshell autostart in the Hyprland Lua payload;
- starts Quickshell from the Hyprland start callback after Hypr-Lab session initialization;
- removes the release-machine `.welcome-disabled` state so Welcome appears on
  first graphical login;
- resets monitor state to a clean `[]` during installation;
- keeps browser selection XDG-based;
- keeps file-manager selection detected/runtime-safe;
- installs the custom `Bibata-Modern-Hypr-Lab` cursor by default;
- installs `Fluent-teal-dark` icons by default;
- applies cursor/icon settings for GTK and the user session;
- keeps Ghostty configuration and Fastfetch configuration user-owned;
- records packages installed by Hypr-Lab so `uninstall.sh` can safely offer dependency removal.

## Install

Extract the release and run as your normal user:

```bash
chmod +x install.sh
./install.sh
```

Do **not** run the installer as root. It requests `sudo` only where system
changes are needed.

On a clean Arch installation, reboot after the installer completes. The
default RC3 path is:

```text
greetd -> tuigreet -> start-hyprland -> Hypr-Lab
```

If login-manager configuration was intentionally skipped, start Hyprland from
a TTY with:

```bash
start-hyprland
```

### Installer options

```text
-y, --yes            Accept normal prompts automatically
--skip-deps          Skip Arch package installation/checks
--no-gtk             Do not install Hypr-Lab GTK CSS
--no-themes          Do not install Bibata Hypr-Lab cursor / Fluent icons
--no-login-manager   Do not configure greetd/tuigreet
-h, --help           Show help
```


## Uninstall

RC3 includes a tracked uninstaller:

```bash
./uninstall.sh
```

The default path removes/restores Hypr-Lab configuration, owned themes and login
integration, while keeping Arch packages unless you explicitly approve their removal.

For a full uninstall using the package list recorded by the RC3 installer:

```bash
./uninstall.sh --purge
```

For a non-interactive full purge:

```bash
./uninstall.sh --purge --yes
```

The uninstaller **never guesses a dependency list**. It only offers to remove packages
that the RC3 installer recorded as missing and installed itself. Packages that existed
before Hypr-Lab are not recorded and are therefore not removed. `pacman -Rns` still
performs its normal dependency checks.

If a pre-Hypr-Lab configuration backup is available, the uninstaller restores it by
default. The source Git clone/release directory is deliberately left untouched.

### Uninstaller options

```text
-y, --yes       Accept safe default prompts automatically
--purge         Remove tracked packages and Hypr-Lab state/backups too
--purge-deps    Remove packages recorded as installed by Hypr-Lab
--purge-state   Remove ~/.local/state/hypr-lab after uninstall
--no-restore    Do not restore the pre-Hypr-Lab config backup
--keep-login    Leave greetd/display-manager integration untouched
-h, --help      Show help
```

## Default visual themes

### Cursor

Hypr-Lab builds a custom Bibata cursor locally during installation:

```text
Bibata-Modern-Hypr-Lab
size: 24
inside: black
outline: #37F5EB
```

The build uses the upstream Bibata Modern SVG sources. The upstream project is
not authored by Hypr-Lab; see `THIRD_PARTY_NOTICES.md`.

### Icons

Hypr-Lab installs the upstream Fluent icon theme and selects:

```text
Fluent-teal-dark
```

The theme remains a separate upstream GPL project; see
`THIRD_PARTY_NOTICES.md`.

Theme source is fetched from the upstream repositories at install time. This
keeps the Hypr-Lab repository small while preserving reproducible source-based
installation of the customized cursor.

## Core dependencies

The installer uses official Arch packages for the Hypr-Lab desktop stack,
including Hyprland, Quickshell, Ghostty, PipeWire/WirePlumber, Hypridle,
Hyprpolkitagent, XDG portals, screenshot tools, media support, fonts,
`greetd` and `greetd-tuigreet`.

A browser and file manager are deliberately not forced. Browser launch follows
the user's XDG default. Supported installed file managers are detected by the
installer; if none exists, the runtime wrapper will detect one later.

Theme installation additionally uses Git, Yarn/npm and pipx to build the
Hypr-Lab Bibata variant from upstream source.

## Main shortcuts

| Shortcut | Action |
|---|---|
| `SUPER + SPACE` | App Launcher |
| `SUPER + SHIFT + C` | Control Center |
| `SUPER + SHIFT + V` | Audio Control |
| `SUPER + SHIFT + N` | Notification Center |
| `SUPER + SHIFT + D` | Do Not Disturb |
| `SUPER + SHIFT + W` | Wallpaper Picker |
| `SUPER + W` | Random wallpaper |
| `SUPER + L` | Lock screen |
| `SUPER + ALT + W` | Welcome Screen |
| `SUPER + SHIFT + P` | Power Menu |
| `SUPER + C` | Ghostty |
| `SUPER + E` | Selected/detected file manager |
| `SUPER + B` | XDG default browser |
| `SUPER + M` | Exit Hyprland session |

## Backups

Each installer run stores the replaced user configuration under:

```text
~/.local/state/hypr-lab/backups/<timestamp>/
```

The latest backup path is recorded in:

```text
~/.local/state/hypr-lab/last-backup
```

## Repository layout

```text
Hypr-Lab/
├── config/                 Hypr-Lab user configuration payload
│   ├── hypr/
│   ├── quickshell/
│   ├── gtk-3.0/
│   ├── gtk-4.0/
│   └── wireplumber/
├── system/                 system-level templates installed with sudo
│   └── greetd/config.toml
├── install.sh
├── uninstall.sh
├── manifest.json
├── README.md
├── RELEASE_NOTES.md
├── THIRD_PARTY_NOTICES.md
├── LICENSE
└── .gitignore
```

## License and credits

Hypr-Lab is released under GNU GPL v3.0.

Hypr-Lab began as a personal Arch/Hyprland project by **nadam0607** and was
developed with assistance from **OpenAI ChatGPT**, including code drafting,
debugging, refactoring and installer/test workflow support. Project direction,
testing and release decisions remain with the project maintainer.

Third-party components retain their own copyright and licensing. See
`THIRD_PARTY_NOTICES.md`.
