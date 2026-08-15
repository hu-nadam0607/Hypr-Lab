#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD="${SCRIPT_DIR}/config"
SYSTEM_PAYLOAD="${SCRIPT_DIR}/system"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_DIR="${STATE_HOME}/hypr-lab"

ASSUME_YES=0
SKIP_DEPS=0
INSTALL_GTK=1
INSTALL_THEMES=1
CONFIGURE_LOGIN=1
LANG_CHOICE=""

for arg in "$@"; do
    case "$arg" in
        -y|--yes) ASSUME_YES=1 ;;
        --skip-deps) SKIP_DEPS=1 ;;
        --no-gtk) INSTALL_GTK=0 ;;
        --no-themes) INSTALL_THEMES=0 ;;
        --no-login-manager) CONFIGURE_LOGIN=0 ;;
        --lang=hu) LANG_CHOICE="hu" ;;
        --lang=en) LANG_CHOICE="en" ;;
        -h|--help)
            cat <<EOH
Hypr-Lab ${VERSION} installer / telepítő

Usage / Használat:
  ./install.sh [options]

Options / Opciók:
  -y, --yes            Accept normal prompts automatically.
                       Normál kérdések automatikus elfogadása.
  --skip-deps          Do not install/check Arch packages with pacman.
                       Arch csomagok telepítésének/ellenőrzésének kihagyása.
  --no-gtk             Do not install Hypr-Lab GTK3/GTK4 CSS.
                       Hypr-Lab GTK3/GTK4 CSS telepítésének kihagyása.
  --no-themes          Do not install Bibata Hypr-Lab cursor / Fluent icons.
                       Bibata Hypr-Lab kurzor / Fluent ikonok kihagyása.
  --no-login-manager   Do not configure greetd/tuigreet login.
                       A greetd/tuigreet bejelentkezés konfigurálásának kihagyása.
  --lang=en            Force English installer language.
                       Angol telepítőnyelv kényszerítése.
  --lang=hu            Force Hungarian installer language.
                       Magyar telepítőnyelv kényszerítése.
  -h, --help           Show this help.
                       Súgó megjelenítése.
EOH
            exit 0
            ;;
        *)
            printf "Unknown option / Ismeretlen opció: %s\n" "$arg" >&2
            exit 2
            ;;
    esac
done

if [[ -z "$LANG_CHOICE" ]]; then
    case "${LANG:-}" in
        hu_HU*|hu*) LANG_CHOICE="hu" ;;
        *) LANG_CHOICE="en" ;;
    esac
fi

msg() {
    local en="$1"
    local hu="$2"
    if [[ "$LANG_CHOICE" == "hu" ]]; then
        printf '%s' "$hu"
    else
        printf '%s' "$en"
    fi
}

say() {
    local en="$1"
    local hu="$2"
    if [[ "$LANG_CHOICE" == "hu" ]]; then
        printf '%s\n' "$hu"
    else
        printf '%s\n' "$en"
    fi
}

prompt_text() {
    msg "$1" "$2"
}

if [[ ${EUID} -eq 0 ]]; then
    say "Do not run Hypr-Lab installer as root." "Ne futtasd a Hypr-Lab telepítőt root felhasználóként."
    say "Run it as your normal user; sudo is requested only when required." "Normál felhasználóként indítsd; sudo jogosultságot csak szükség esetén kér."
    exit 1
fi

if [[ ! -f /etc/arch-release ]]; then
    say "Hypr-Lab v1.0 currently targets Arch Linux." "A Hypr-Lab v1.0 jelenleg Arch Linuxot céloz."
    exit 1
fi

if [[ ! -d "$PAYLOAD/quickshell" || ! -d "$PAYLOAD/hypr" ]]; then
    say "Installer payload is incomplete." "A telepítő payloadja hiányos." >&2
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
if [[ "$LANG_CHOICE" == "hu" ]]; then
    echo "A telepítő a következőket végzi el:"
    echo "  • ellenőrzi/telepíti a szükséges Arch csomagokat"
    echo "  • biztonsági mentést készít a meglévő Hypr/Quickshell konfigurációról"
    echo "  • telepíti a Hypr-Lab shellt és a Hyprland Lua konfigurációt"
    echo "  • beállítja a felismert fájlkezelőt"
    echo "  • az alapértelmezett böngészőt XDG-alapon kezeli"
    echo "  • telepíti az értesítési hanghoz szükséges WirePlumber szabályt"
    echo "  • opcionálisan telepíti a Hypr-Lab GTK CSS-t"
    echo "  • alapértelmezetten telepíti a Bibata-Modern-Hypr-Lab kurzort és a Fluent-teal-dark ikonokat"
    echo "  • beállítja a greetd/tuigreet login folyamatot start-hyprland indítással"
    echo
    echo "NEM telepít egyedi Ghostty- vagy Fastfetch-konfigurációt."
else
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
fi
echo

if ! confirm "$(prompt_text "Continue with Hypr-Lab installation?" "Folytatod a Hypr-Lab telepítését?")" y; then
    say "Cancelled." "Megszakítva."
    exit 0
fi

mkdir -p "$STATE_DIR"

# ------------------------------------------------------------
# 1. Dependencies
# ------------------------------------------------------------

MANAGED_PACKAGES_FILE="${STATE_DIR}/installed-packages.txt"
touch "$MANAGED_PACKAGES_FILE"

record_managed_packages() {
    local pkg
    for pkg in "$@"; do
        grep -qxF "$pkg" "$MANAGED_PACKAGES_FILE" 2>/dev/null || printf '%s\n' "$pkg" >> "$MANAGED_PACKAGES_FILE"
    done
}

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
    say "[1/11] Checking dependencies..." "[1/11] Függőségek ellenőrzése..."

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
        say "Missing packages:" "Hiányzó csomagok:"
        printf '  • %s\n' "${missing[@]}"
        echo

        if confirm "$(prompt_text "Install missing packages with pacman?" "Telepíted a hiányzó csomagokat pacmannel?")" y; then
            sudo pacman -S --needed "${missing[@]}"
            record_managed_packages "${missing[@]}"
        else
            say "Cannot guarantee a working Hypr-Lab installation without them." "Nélkülük nem garantálható a Hypr-Lab megfelelő működése."
            exit 1
        fi
    else
        say "  All required packages are installed." "  Minden szükséges csomag telepítve van."
    fi
else
    echo
    say "[1/11] Dependency installation skipped by request." "[1/11] A függőségek telepítése kérésre kihagyva."
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
    read -rp "$(prompt_text "Keyboard layout" "Billentyűzetkiosztás") [${DETECTED_LAYOUT}]: " entered_layout
    KB_LAYOUT="${entered_layout:-$DETECTED_LAYOUT}"
fi

if [[ ! "$KB_LAYOUT" =~ ^[A-Za-z0-9_,+-]+$ ]]; then
    say "Unsupported keyboard-layout value: $KB_LAYOUT" "Nem támogatott billentyűzetkiosztás-érték: $KB_LAYOUT" >&2
    exit 1
fi

# ------------------------------------------------------------
# 2. Backup
# ------------------------------------------------------------

echo
say "[2/11] Creating backup..." "[2/11] Biztonsági mentés készítése..."

STAMP="$(date +%Y%m%d-%H%M%S)"
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
if sudo test -f /etc/greetd/config.toml; then
    sudo cp -a /etc/greetd/config.toml "${BACKUP_ROOT}/greetd-config.toml"
    sudo chown "${USER}:$(id -gn)" "${BACKUP_ROOT}/greetd-config.toml" 2>/dev/null || true
fi

printf '%s\n' "$BACKUP_ROOT" > "${STATE_DIR}/last-backup"
if [[ ! -f "${STATE_DIR}/original-backup" ]]; then
    oldest_backup="$(find "${STATE_DIR}/backups" -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null | sort | head -n1 || true)"
    [[ -n "$oldest_backup" ]] && printf '%s\n' "$oldest_backup" > "${STATE_DIR}/original-backup"
fi
say "  Backup: $BACKUP_ROOT" "  Biztonsági mentés: $BACKUP_ROOT"

# ------------------------------------------------------------
# 3. Install clean config
# ------------------------------------------------------------

echo
say "[3/11] Installing Hypr-Lab configuration..." "[3/11] Hypr-Lab konfiguráció telepítése..."

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
    raise SystemExit("Keyboard-layout placeholder not found in hyprland.lua / A billentyűzetkiosztás-placeholder nem található a hyprland.lua fájlban")
path.write_text(text.replace(marker, layout, 1))
PY

find "${HOME}/.config/hypr" -type f -name '*.sh' -exec chmod +x {} +

# Fresh user-specific monitor state.
printf '[]\n' > "${HOME}/.config/hypr/hyprlab-settings/monitors.json"

# ------------------------------------------------------------
# 4. File manager selection
# ------------------------------------------------------------

echo
say "[4/11] Detecting file managers..." "[4/11] Fájlkezelők felismerése..."

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
    say "  Using ${FM_NAMES[0]}." "  Használatban: ${FM_NAMES[0]}."
elif ((${#FM_CMDS[@]} > 1)); then
    say "  Detected:" "  Felismerve:"
    for i in "${!FM_CMDS[@]}"; do
        printf '    %d) %s [%s]\n' "$((i + 1))" "${FM_NAMES[$i]}" "${FM_CMDS[$i]}"
    done

    if (( ASSUME_YES )); then
        selected_fm="${FM_CMDS[0]}"
        say "  --yes: using ${FM_NAMES[0]}." "  --yes: ${FM_NAMES[0]} használata."
    else
        while true; do
            read -rp "$(prompt_text "  Choose file manager" "  Válassz fájlkezelőt") [1-${#FM_CMDS[@]}]: " choice
            if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#FM_CMDS[@]} )); then
                selected_fm="${FM_CMDS[$((choice - 1))]}"
                break
            fi
            say "  Invalid choice." "  Érvénytelen választás."
        done
    fi
else
    say "  No supported file manager detected." "  Nem található támogatott fájlkezelő."
    say "  SUPER+E will use the runtime auto-detect wrapper until one is installed." "  A SUPER+E a futásidejű automatikus felismerést használja, amíg nem telepítesz támogatott fájlkezelőt."
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
say "[5/11] Installing notification-audio configuration..." "[5/11] Értesítési hang konfigurációjának telepítése..."

mkdir -p "${HOME}/.config/wireplumber/wireplumber.conf.d"
install -Dm644 \
    "${PAYLOAD}/wireplumber/wireplumber.conf.d/51-hyprlab-nosuspend.conf" \
    "${HOME}/.config/wireplumber/wireplumber.conf.d/51-hyprlab-nosuspend.conf"

systemctl --user restart wireplumber 2>/dev/null || true

# ------------------------------------------------------------
# 6. Hypr-Lab cursor + Fluent icon theme
# ------------------------------------------------------------

echo
say "[6/11] Desktop themes..." "[6/11] Asztali témák..."

install_bibata_hyprlab() {
    local tmp
    tmp="$(mktemp -d)"
    local repo="${tmp}/Bibata_Cursor"

    say "  Building Bibata-Modern-Hypr-Lab..." "  Bibata-Modern-Hypr-Lab építése..."
    git clone --depth 1 --branch v2.0.7 https://github.com/ful1e5/Bibata_Cursor.git "$repo" >/dev/null 2>&1 || { rm -rf "$tmp"; return 1; }

    (
        cd "$repo"
        export PATH="${HOME}/.local/bin:${PATH}"
        export PUPPETEER_SKIP_DOWNLOAD=1

        yarn install >/dev/null 2>&1

        if ! command -v ctgen >/dev/null 2>&1; then
            touch "${STATE_DIR}/clickgen-managed"
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

    say "  Installing Fluent teal icons..." "  Fluent teal ikonok telepítése..."
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
    if [[ ! -d "${HOME}/.local/share/icons/Bibata-Modern-Hypr-Lab" ]]; then
        touch "${STATE_DIR}/bibata-managed"
    fi
    if [[ ! -d "${HOME}/.local/share/icons/Fluent-teal-dark" ]]; then
        touch "${STATE_DIR}/fluent-teal-managed"
    fi
    if command -v gsettings >/dev/null 2>&1; then
        [[ -f "${STATE_DIR}/previous-cursor-theme" ]] || gsettings get org.gnome.desktop.interface cursor-theme > "${STATE_DIR}/previous-cursor-theme" 2>/dev/null || true
        [[ -f "${STATE_DIR}/previous-cursor-size" ]] || gsettings get org.gnome.desktop.interface cursor-size > "${STATE_DIR}/previous-cursor-size" 2>/dev/null || true
        [[ -f "${STATE_DIR}/previous-icon-theme" ]] || gsettings get org.gnome.desktop.interface icon-theme > "${STATE_DIR}/previous-icon-theme" 2>/dev/null || true
    fi
    if install_bibata_hyprlab; then
        say "  Bibata-Modern-Hypr-Lab installed." "  Bibata-Modern-Hypr-Lab telepítve."
    else
        warn "Bibata-Modern-Hypr-Lab build failed; Hypr-Lab core installation will continue." "A Bibata-Modern-Hypr-Lab build sikertelen; a Hypr-Lab alaptelepítése folytatódik."
        THEMES_OK=0
    fi

    if install_fluent_teal; then
        say "  Fluent teal icon theme installed." "  Fluent teal ikontéma telepítve."
    else
        warn "Fluent teal icon installation failed; Hypr-Lab core installation will continue." "A Fluent teal ikonok telepítése sikertelen; a Hypr-Lab alaptelepítése folytatódik."
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
    say "  Theme installation disabled with --no-themes." "  A témák telepítése letiltva a --no-themes opcióval."
fi

# ------------------------------------------------------------
# 7. GTK integration
# ------------------------------------------------------------

echo
say "[7/11] GTK integration..." "[7/11] GTK integráció..."

if (( INSTALL_GTK )); then
    if (( ASSUME_YES )) || confirm "$(prompt_text "Install Hypr-Lab GTK3/GTK4 CSS?" "Telepíted a Hypr-Lab GTK3/GTK4 CSS-t?")" y; then
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
        say "  GTK integration installed." "  GTK integráció telepítve."
    else
        say "  GTK CSS skipped." "  GTK CSS kihagyva."
    fi
else
    say "  GTK CSS disabled with --no-gtk." "  GTK CSS letiltva a --no-gtk opcióval."
fi

# ------------------------------------------------------------
# 8. Login manager / session startup
# ------------------------------------------------------------

echo
say "[8/11] Configuring Hypr-Lab login session..." "[8/11] Hypr-Lab bejelentkezési munkamenet beállítása..."

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
        say "  Existing display manager detected: $other_dm" "  Meglévő display manager felismerve: $other_dm"
        if (( ASSUME_YES )); then
            say "  --yes: leaving the existing display manager untouched." "  --yes: a meglévő display manager érintetlen marad."
            configure_greetd=0
        elif ! confirm "$(prompt_text "Replace its next-boot login with greetd/tuigreet for Hypr-Lab?" "A következő boot bejelentkezését lecseréled greetd/tuigreet-re a Hypr-Labhoz?")" n; then
            configure_greetd=0
        else
            printf '%s\n' "$other_dm" > "${STATE_DIR}/previous-display-manager"
            sudo systemctl disable "$other_dm" >/dev/null 2>&1 || true
        fi
    fi

    if (( configure_greetd )); then
        if systemctl is-enabled greetd.service >/dev/null 2>&1 && [[ ! -f "${STATE_DIR}/greetd-managed" ]]; then
            touch "${STATE_DIR}/greetd-was-enabled"
        fi
        sudo install -Dm644 "${SYSTEM_PAYLOAD}/greetd/config.toml" /etc/greetd/config.toml
        sudo systemctl enable greetd.service >/dev/null
        touch "${STATE_DIR}/greetd-managed"
        say "  greetd enabled; successful login launches start-hyprland." "  greetd engedélyezve; sikeres bejelentkezéskor a start-hyprland indul."
    else
        say "  greetd configuration skipped." "  greetd konfiguráció kihagyva."
    fi
else
    say "  Login-manager configuration disabled with --no-login-manager." "  A login manager konfigurálása letiltva a --no-login-manager opcióval."
fi

# ------------------------------------------------------------
# 9. User directories / portal environment
# ------------------------------------------------------------

echo
say "[9/11] Finalizing desktop integration..." "[9/11] Asztali integráció véglegesítése..."

xdg-user-dirs-update >/dev/null 2>&1 || true

if [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
    systemctl --user daemon-reload >/dev/null 2>&1 || true
fi

# ------------------------------------------------------------
# 10. Verification
# ------------------------------------------------------------

echo
say "[10/11] Verifying installed files..." "[10/11] Telepített fájlok ellenőrzése..."

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
        if [[ "$LANG_CHOICE" == "hu" ]]; then
            echo "  HIÁNYZIK: $file"
        else
            echo "  MISSING: $file"
        fi
        failed=1
    fi
done

if (( failed )); then
    echo
    say "Installation payload verification failed." "A telepített payload ellenőrzése sikertelen."
    say "Backup is available at:" "A biztonsági mentés itt található:"
    echo "  $BACKUP_ROOT"
    exit 1
fi

say "  Core payload verified." "  Alap payload ellenőrizve."

# ------------------------------------------------------------
# 11. Summary
# ------------------------------------------------------------

echo
say "[11/11] Install summary" "[11/11] Telepítési összegzés"
echo
echo "========================================================"
if [[ "$LANG_CHOICE" == "hu" ]]; then
    echo "             HYPR-LAB TELEPÍTÉS KÉSZ"
else
    echo "               HYPR-LAB INSTALL COMPLETE"
fi
echo "========================================================"
echo
if [[ "$LANG_CHOICE" == "hu" ]]; then
    echo "Verzió:            ${VERSION}"
    echo "Billentyűzet:       ${KB_LAYOUT}"
    echo "Biztonsági mentés:  ${BACKUP_ROOT}"
else
    echo "Version:          ${VERSION}"
    echo "Keyboard layout:  ${KB_LAYOUT}"
    echo "Backup:           ${BACKUP_ROOT}"
fi
if (( INSTALL_THEMES )); then
    echo "Cursor:           Bibata-Modern-Hypr-Lab (24)"
    echo "Icons:            Fluent-teal-dark"
    if (( ! THEMES_OK )); then
        say "Theme status:      completed with warning(s)" "Témaállapot:        figyelmeztetéssel fejeződött be"
    fi
fi
echo
if [[ "$LANG_CHOICE" == "hu" ]]; then
    echo "Ajánlott következő lépés:"
    echo "  Indítsd újra a gépet. Tiszta Arch telepítésen a greetd/tuigreet biztosítja"
    echo "  a Hypr-Lab bejelentkezést, majd a start-hyprland indítja a Hyprlandet."
    echo
    echo "Ha szándékosan kihagytad a greetd beállítását, TTY-ből indítsd a munkamenetet ezzel:"
    echo "  start-hyprland"
    echo
    echo "Az első grafikus bejelentkezéskor a Welcome Screennek automatikusan meg kell jelennie."
    echo
    echo "Hasznos gyorsbillentyűk:"
    echo "  SUPER+SPACE       App Launcher"
    echo "  SUPER+SHIFT+C     Control Center"
    echo "  SUPER+SHIFT+V     Audio Control"
    echo "  SUPER+SHIFT+N     Notification Center"
    echo "  SUPER+SHIFT+W     Wallpaper Picker"
    echo "  SUPER+L           Képernyőzár"
    echo
    echo "Jó Hypr-Lab használatot!"
else
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
fi
