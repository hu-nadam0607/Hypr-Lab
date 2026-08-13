#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0-rc2"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD="${SCRIPT_DIR}/config"
SYSTEM_PAYLOAD="${SCRIPT_DIR}/system"

ASSUME_YES=0
SKIP_DEPS=0
INSTALL_GTK=1
INSTALL_THEMES=1
CONFIGURE_LOGIN=1

for arg in "$@"; do
    case "$arg" in
        -y|--yes) ASSUME_YES=1 ;;
        --skip-deps) SKIP_DEPS=1 ;;
        --no-gtk) INSTALL_GTK=0 ;;
        --no-themes) INSTALL_THEMES=0 ;;
        --no-login-manager) CONFIGURE_LOGIN=0 ;;
        -h|--help)
            cat <<EOH
Hypr-Lab ${VERSION} installer

Usage:
  ./install.sh [options]

Options:
  -y, --yes            Accept normal prompts automatically.
  --skip-deps          Do not install/check Arch packages with pacman.
  --no-gtk             Do not install Hypr-Lab GTK3/GTK4 CSS.
  --no-themes          Do not install Bibata Hypr-Lab cursor / Fluent icons.
  --no-login-manager   Do not configure greetd/tuigreet login.
  -h, --help           Show this help.
EOH
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            exit 2
            ;;
    esac
done

if [[ ${EUID} -eq 0 ]]; then
    echo "Do not run Hypr-Lab installer as root."
    echo "Run it as your normal user; sudo is requested only when required."
    exit 1
fi

if [[ ! -f /etc/arch-release ]]; then
    echo "Hypr-Lab v1.0 currently targets Arch Linux."
    exit 1
fi

if [[ ! -d "$PAYLOAD/quickshell" || ! -d "$PAYLOAD/hypr" ]]; then
    echo "Installer payload is incomplete." >&2
    exit 1
fi

confirm() {
    local prompt="$1"
    local default="${2:-y}"

    if (( ASSUME_YES )); then
        [[ "$default" == "y" ]]
        return
    fi

    local answer
    if [[ "$default" == "y" ]]; then
        read -rp "${prompt} [Y/n] " answer
        answer="${answer:-y}"
    else
        read -rp "${prompt} [y/N] " answer
        answer="${answer:-n}"
    fi

    [[ "$answer" =~ ^[Yy]$ ]]
}

warn() {
    printf 'WARNING: %s\n' "$*" >&2
}

echo
echo "========================================================"
echo "                  HYPR-LAB ${VERSION}"
echo "========================================================"
echo
echo "This installer will:"
echo "  • install/check required Arch packages"
echo "  • back up existing Hypr/Quickshell configuration"
echo "  • install the Hypr-Lab shell and Hyprland Lua config"
echo "  • configure the detected file manager"
echo "  • keep your/default browser selection XDG-based"
echo "  • install the notification-audio WirePlumber rule"
echo "  • optionally install Hypr-Lab GTK CSS"
echo "  • install Bibata-Modern-Hypr-Lab + Fluent-teal-dark by default"
echo "  • configure greetd/tuigreet to launch Hyprland with start-hyprland"
echo
echo "It does NOT install a custom Ghostty config or Fastfetch config."
echo

if ! confirm "Continue with Hypr-Lab installation?" y; then
    echo "Cancelled."
    exit 0
fi

# ------------------------------------------------------------
# 1. Dependencies
# ------------------------------------------------------------

REQUIRED_PACKAGES=(
    hyprland
    quickshell
    ghostty
    hypridle
    hyprpolkitagent
    pipewire
    pipewire-pulse
    pipewire-jack
    wireplumber
    qt6-multimedia
    qt6-multimedia-ffmpeg
    playerctl
    grim
    slurp
    zenity
    cava
    libnotify
    udisks2
    jq
    brightnessctl
    xdg-utils
    xdg-user-dirs
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    inter-font
    ttf-jetbrains-mono-nerd
    greetd
    greetd-tuigreet
)

THEME_BUILD_PACKAGES=(
    git
    yarn
    npm
    python-pipx
)

if (( ! SKIP_DEPS )); then
    echo
    echo "[1/11] Checking dependencies..."

    missing=()
    for pkg in "${REQUIRED_PACKAGES[@]}"; do
        if ! pacman -Q "$pkg" >/dev/null 2>&1; then
            missing+=("$pkg")
        fi
    done

    if (( INSTALL_THEMES )); then
        for pkg in "${THEME_BUILD_PACKAGES[@]}"; do
            if ! pacman -Q "$pkg" >/dev/null 2>&1; then
                missing+=("$pkg")
            fi
        done
    fi

    if ((${#missing[@]})); then
        echo
        echo "Missing packages:"
        printf '  • %s\n' "${missing[@]}"
        echo

        if confirm "Install missing packages with pacman?" y; then
            sudo pacman -S --needed "${missing[@]}"
        else
            echo "Cannot guarantee a working Hypr-Lab installation without them."
            exit 1
        fi
    else
        echo "  All required packages are installed."
    fi
else
    echo
    echo "[1/11] Dependency installation skipped by request."
fi

# ------------------------------------------------------------
# Resolve keyboard layout BEFORE replacing existing config.
# ------------------------------------------------------------

detect_layout() {
    local layout=""

    if [[ -f "${HOME}/.config/hypr/hyprland.lua" ]]; then
        layout="$(
            sed -nE 's/.*kb_layout[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' \
            "${HOME}/.config/hypr/hyprland.lua" | head -n1
        )"
    fi

    if [[ -z "$layout" ]] && command -v localectl >/dev/null 2>&1; then
        layout="$(
            localectl status 2>/dev/null \
            | sed -nE 's/^[[:space:]]*X11 Layout:[[:space:]]*//p' \
            | head -n1
        )"
    fi

    [[ -n "$layout" ]] || layout="us"
    printf '%s' "$layout"
}

DETECTED_LAYOUT="$(detect_layout)"
KB_LAYOUT="$DETECTED_LAYOUT"

if (( ! ASSUME_YES )); then
    echo
    read -rp "Keyboard layout [${DETECTED_LAYOUT}]: " entered_layout
    KB_LAYOUT="${entered_layout:-$DETECTED_LAYOUT}"
fi

if [[ ! "$KB_LAYOUT" =~ ^[A-Za-z0-9_,+-]+$ ]]; then
    echo "Unsupported keyboard-layout value: $KB_LAYOUT" >&2
    exit 1
fi

# ------------------------------------------------------------
# 2. Backup
# ------------------------------------------------------------

echo
echo "[2/11] Creating backup..."

STAMP="$(date +%Y%m%d-%H%M%S)"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
BACKUP_ROOT="${STATE_HOME}/hypr-lab/backups/${STAMP}"
mkdir -p "$BACKUP_ROOT"

backup_path() {
    local path="$1"
    local name="$2"
    if [[ -e "$path" || -L "$path" ]]; then
        cp -a "$path" "${BACKUP_ROOT}/${name}"
    fi
}

backup_path "${HOME}/.config/hypr" "hypr"
backup_path "${HOME}/.config/quickshell" "quickshell"
backup_path "${HOME}/.config/wireplumber/wireplumber.conf.d/51-hyprlab-nosuspend.conf" "51-hyprlab-nosuspend.conf"
backup_path "${HOME}/.config/gtk-3.0/gtk.css" "gtk3.css"
backup_path "${HOME}/.config/gtk-4.0/gtk.css" "gtk4.css"
backup_path "${HOME}/.config/gtk-3.0/settings.ini" "gtk3-settings.ini"
backup_path "${HOME}/.config/gtk-4.0/settings.ini" "gtk4-settings.ini"
backup_path "${HOME}/.config/environment.d/hyprlab-cursor.conf" "hyprlab-cursor.conf"

printf '%s\n' "$BACKUP_ROOT" > "${STATE_HOME}/hypr-lab/last-backup"
echo "  Backup: $BACKUP_ROOT"

# ------------------------------------------------------------
# 3. Install clean config
# ------------------------------------------------------------

echo
echo "[3/11] Installing Hypr-Lab configuration..."

rm -rf "${HOME}/.config/hypr" "${HOME}/.config/quickshell"
mkdir -p "${HOME}/.config"

cp -a "${PAYLOAD}/hypr" "${HOME}/.config/hypr"
cp -a "${PAYLOAD}/quickshell" "${HOME}/.config/quickshell"

# Fresh installs must show Welcome; never ship release-machine state.
rm -f "${HOME}/.config/quickshell/.welcome-disabled"

python3 - "$HOME/.config/hypr/hyprland.lua" "$KB_LAYOUT" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
layout = sys.argv[2]
text = path.read_text()
marker = '__HYPRLAB_KB_LAYOUT__'
if marker not in text:
    raise SystemExit("Keyboard-layout placeholder not found in hyprland.lua")
path.write_text(text.replace(marker, layout, 1))
PY

find "${HOME}/.config/hypr" -type f -name '*.sh' -exec chmod +x {} +

# Fresh user-specific monitor state.
printf '[]\n' > "${HOME}/.config/hypr/hyprlab-settings/monitors.json"

# ------------------------------------------------------------
# 4. File manager selection
# ------------------------------------------------------------

echo
echo "[4/11] Detecting file managers..."

declare -a FM_NAMES=()
declare -a FM_CMDS=()

add_fm() {
    local name="$1"
    local cmd="$2"
    if command -v "$cmd" >/dev/null 2>&1; then
        FM_NAMES+=("$name")
        FM_CMDS+=("$cmd")
    fi
}

add_fm "Nautilus" "nautilus"
add_fm "Thunar" "thunar"
add_fm "Dolphin" "dolphin"
add_fm "Nemo" "nemo"
add_fm "PCManFM-Qt" "pcmanfm-qt"
add_fm "PCManFM" "pcmanfm"

selected_fm=""

if ((${#FM_CMDS[@]} == 1)); then
    selected_fm="${FM_CMDS[0]}"
    echo "  Using ${FM_NAMES[0]}."
elif ((${#FM_CMDS[@]} > 1)); then
    echo "  Detected:"
    for i in "${!FM_CMDS[@]}"; do
        printf '    %d) %s [%s]\n' "$((i + 1))" "${FM_NAMES[$i]}" "${FM_CMDS[$i]}"
    done

    if (( ASSUME_YES )); then
        selected_fm="${FM_CMDS[0]}"
        echo "  --yes: using ${FM_NAMES[0]}."
    else
        while true; do
            read -rp "  Choose file manager [1-${#FM_CMDS[@]}]: " choice
            if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#FM_CMDS[@]} )); then
                selected_fm="${FM_CMDS[$((choice - 1))]}"
                break
            fi
            echo "  Invalid choice."
        done
    fi
else
    echo "  No supported file manager detected."
    echo "  SUPER+E will use the runtime auto-detect wrapper until one is installed."
fi

if [[ -n "$selected_fm" ]]; then
    cat > "${HOME}/.config/hypr/settings/filemanager.sh" <<EOF_FM
#!/usr/bin/env bash
set -euo pipefail
exec ${selected_fm}
EOF_FM
    chmod +x "${HOME}/.config/hypr/settings/filemanager.sh"
fi

# ------------------------------------------------------------
# 5. WirePlumber
# ------------------------------------------------------------

echo
echo "[5/11] Installing notification-audio configuration..."

mkdir -p "${HOME}/.config/wireplumber/wireplumber.conf.d"
install -Dm644 \
    "${PAYLOAD}/wireplumber/wireplumber.conf.d/51-hyprlab-nosuspend.conf" \
    "${HOME}/.config/wireplumber/wireplumber.conf.d/51-hyprlab-nosuspend.conf"

systemctl --user restart wireplumber 2>/dev/null || true

# ------------------------------------------------------------
# 6. Hypr-Lab cursor + Fluent icon theme
# ------------------------------------------------------------

echo
echo "[6/11] Desktop themes..."

install_bibata_hyprlab() {
    local tmp
    tmp="$(mktemp -d)"
    local repo="${tmp}/Bibata_Cursor"

    echo "  Building Bibata-Modern-Hypr-Lab..."
    git clone --depth 1 --branch v2.0.7 https://github.com/ful1e5/Bibata_Cursor.git "$repo" >/dev/null 2>&1 || { rm -rf "$tmp"; return 1; }

    (
        cd "$repo"
        export PATH="${HOME}/.local/bin:${PATH}"
        export PUPPETEER_SKIP_DOWNLOAD=1

        yarn install >/dev/null 2>&1

        if ! command -v ctgen >/dev/null 2>&1; then
            pipx install clickgen >/dev/null 2>&1 || pipx upgrade clickgen >/dev/null 2>&1
        fi
        export PATH="${HOME}/.local/bin:${PATH}"

        cat > render-hyprlab.json <<'JSON'
{
  "Bibata-Modern-Hypr-Lab": {
    "dir": "svg/modern",
    "out": "bitmaps/Bibata-Modern-Hypr-Lab",
    "colors": [
      { "match": "#00FF00", "replace": "#000000" },
      { "match": "#0000FF", "replace": "#37F5EB" },
      { "match": "#FF0000", "replace": "#0A0A0E" }
    ]
  }
}
JSON

        npx cbmp render-hyprlab.json >/dev/null
        ctgen configs/normal/x.build.toml \
            -p x11 \
            -d bitmaps/Bibata-Modern-Hypr-Lab \
            -n Bibata-Modern-Hypr-Lab \
            -c "Black Bibata Modern with Hypr-Lab cyan outline" >/dev/null

        mkdir -p "${HOME}/.local/share/icons"
        rm -rf "${HOME}/.local/share/icons/Bibata-Modern-Hypr-Lab"
        cp -a themes/Bibata-Modern-Hypr-Lab "${HOME}/.local/share/icons/"
        cp -f LICENSE "${HOME}/.local/share/icons/Bibata-Modern-Hypr-Lab/LICENSE" 2>/dev/null || true
    )
    local rc=$?
    rm -rf "$tmp"
    return "$rc"
}

install_fluent_teal() {
    local tmp
    tmp="$(mktemp -d)"
    local repo="${tmp}/Fluent-icon-theme"

    echo "  Installing Fluent teal icons..."
    git clone --depth 1 --branch 2026-07-27 https://github.com/vinceliuice/Fluent-icon-theme.git "$repo" >/dev/null 2>&1 || { rm -rf "$tmp"; return 1; }

    (
        cd "$repo"
        ./install.sh teal >/dev/null
    )
    local rc=$?
    rm -rf "$tmp"
    return "$rc"
}

THEMES_OK=1
if (( INSTALL_THEMES )); then
    if install_bibata_hyprlab; then
        echo "  Bibata-Modern-Hypr-Lab installed."
    else
        warn "Bibata-Modern-Hypr-Lab build failed; Hypr-Lab core installation will continue."
        THEMES_OK=0
    fi

    if install_fluent_teal; then
        echo "  Fluent teal icon theme installed."
    else
        warn "Fluent teal icon installation failed; Hypr-Lab core installation will continue."
        THEMES_OK=0
    fi

    mkdir -p "${HOME}/.config/environment.d"
    cat > "${HOME}/.config/environment.d/hyprlab-cursor.conf" <<'EOF_ENV'
XCURSOR_THEME=Bibata-Modern-Hypr-Lab
XCURSOR_SIZE=24
EOF_ENV

    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Hypr-Lab' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true
        gsettings set org.gnome.desktop.interface icon-theme 'Fluent-teal-dark' 2>/dev/null || true
    fi
else
    echo "  Theme installation disabled with --no-themes."
fi

# ------------------------------------------------------------
# 7. GTK integration
# ------------------------------------------------------------

echo
echo "[7/11] GTK integration..."

if (( INSTALL_GTK )); then
    if (( ASSUME_YES )) || confirm "Install Hypr-Lab GTK3/GTK4 CSS?" y; then
        mkdir -p "${HOME}/.config/gtk-3.0" "${HOME}/.config/gtk-4.0"
        install -Dm644 "${PAYLOAD}/gtk-3.0/gtk.css" "${HOME}/.config/gtk-3.0/gtk.css"
        install -Dm644 "${PAYLOAD}/gtk-4.0/gtk.css" "${HOME}/.config/gtk-4.0/gtk.css"

        if (( INSTALL_THEMES )); then
            for gtkdir in "${HOME}/.config/gtk-3.0" "${HOME}/.config/gtk-4.0"; do
                cat > "${gtkdir}/settings.ini" <<'EOF_GTK'
[Settings]
gtk-icon-theme-name=Fluent-teal-dark
gtk-cursor-theme-name=Bibata-Modern-Hypr-Lab
gtk-cursor-theme-size=24
EOF_GTK
            done
        fi
        echo "  GTK integration installed."
    else
        echo "  GTK CSS skipped."
    fi
else
    echo "  GTK CSS disabled with --no-gtk."
fi

# ------------------------------------------------------------
# 8. Login manager / session startup
# ------------------------------------------------------------

echo
echo "[8/11] Configuring Hypr-Lab login session..."

if (( CONFIGURE_LOGIN )); then
    other_dm=""
    for svc in sddm.service gdm.service lightdm.service ly.service; do
        if systemctl is-enabled "$svc" >/dev/null 2>&1; then
            other_dm="$svc"
            break
        fi
    done

    configure_greetd=1
    if [[ -n "$other_dm" ]]; then
        echo "  Existing display manager detected: $other_dm"
        if (( ASSUME_YES )); then
            echo "  --yes: leaving the existing display manager untouched."
            configure_greetd=0
        elif ! confirm "Replace its next-boot login with greetd/tuigreet for Hypr-Lab?" n; then
            configure_greetd=0
        else
            sudo systemctl disable "$other_dm" >/dev/null 2>&1 || true
        fi
    fi

    if (( configure_greetd )); then
        sudo install -Dm644 "${SYSTEM_PAYLOAD}/greetd/config.toml" /etc/greetd/config.toml
        sudo systemctl enable greetd.service >/dev/null
        echo "  greetd enabled; successful login launches start-hyprland."
    else
        echo "  greetd configuration skipped."
    fi
else
    echo "  Login-manager configuration disabled with --no-login-manager."
fi

# ------------------------------------------------------------
# 9. User directories / portal environment
# ------------------------------------------------------------

echo
echo "[9/11] Finalizing desktop integration..."

xdg-user-dirs-update >/dev/null 2>&1 || true

if [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
    systemctl --user daemon-reload >/dev/null 2>&1 || true
fi

# ------------------------------------------------------------
# 10. Verification
# ------------------------------------------------------------

echo
echo "[10/11] Verifying installed files..."

required_files=(
    "${HOME}/.config/hypr/hyprland.lua"
    "${HOME}/.config/hypr/hypridle.conf"
    "${HOME}/.config/hypr/hyprlab-scripts/hyprlab-settings.sh"
    "${HOME}/.config/hypr/hyprlab-scripts/hyprlab-xdg.sh"
    "${HOME}/.config/quickshell/shell.qml"
    "${HOME}/.config/quickshell/components/CenterIsland.qml"
    "${HOME}/.config/quickshell/components/controlcenter/ControlCenter.qml"
    "${HOME}/.config/quickshell/components/UsbManager.qml"
    "${HOME}/.config/quickshell/components/Welcome.qml"
    "${HOME}/.config/quickshell/assets/sounds/notification-pop.wav"
)

failed=0
for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "  MISSING: $file"
        failed=1
    fi
done

if (( failed )); then
    echo
    echo "Installation payload verification failed."
    echo "Backup is available at:"
    echo "  $BACKUP_ROOT"
    exit 1
fi

echo "  Core payload verified."

# ------------------------------------------------------------
# 11. Summary
# ------------------------------------------------------------

echo
echo "[11/11] Install summary"
echo
echo "========================================================"
echo "               HYPR-LAB INSTALL COMPLETE"
echo "========================================================"
echo
echo "Version:          ${VERSION}"
echo "Keyboard layout:  ${KB_LAYOUT}"
echo "Backup:           ${BACKUP_ROOT}"
if (( INSTALL_THEMES )); then
    echo "Cursor:           Bibata-Modern-Hypr-Lab (24)"
    echo "Icons:            Fluent-teal-dark"
    (( THEMES_OK )) || echo "Theme status:      completed with warning(s)"
fi
echo
echo "Recommended next step:"
echo "  Reboot. greetd/tuigreet will provide the Hypr-Lab login and launch"
echo "  Hyprland through start-hyprland on a clean Arch installation."
echo
echo "If you intentionally skipped greetd, start the session from a TTY with:"
echo "  start-hyprland"
echo
echo "On first graphical login the Welcome Screen should appear automatically."
echo
echo "Useful shortcuts:"
echo "  SUPER+SPACE       App Launcher"
echo "  SUPER+SHIFT+C     Control Center"
echo "  SUPER+SHIFT+V     Audio Control"
echo "  SUPER+SHIFT+N     Notification Center"
echo "  SUPER+SHIFT+W     Wallpaper Picker"
echo "  SUPER+L           Lock"
echo
echo "Enjoy Hypr-Lab."
