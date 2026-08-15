#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_DIR="${STATE_HOME}/hypr-lab"

ASSUME_YES=0
PURGE_DEPS=0
PURGE_STATE=0
RESTORE_BACKUP=1
KEEP_LOGIN=0
LANG_CHOICE=""

for arg in "$@"; do
    case "$arg" in
        -y|--yes) ASSUME_YES=1 ;;
        --purge) PURGE_DEPS=1; PURGE_STATE=1 ;;
        --purge-deps) PURGE_DEPS=1 ;;
        --purge-state) PURGE_STATE=1 ;;
        --no-restore) RESTORE_BACKUP=0 ;;
        --keep-login) KEEP_LOGIN=1 ;;
        --lang=hu) LANG_CHOICE="hu" ;;
        --lang=en) LANG_CHOICE="en" ;;
        -h|--help)
            cat <<EOH
Hypr-Lab ${VERSION} uninstaller / eltávolító

Usage / Használat:
  ./uninstall.sh [options]

Default behavior removes Hypr-Lab configuration, owned themes and login integration,
then offers to remove packages installed by Hypr-Lab.
Alapértelmezetten eltávolítja a Hypr-Lab konfigurációját, a Hypr-Lab által kezelt
témákat és login-integrációt, majd felajánlja a Hypr-Lab által telepített csomagok eltávolítását.

Options / Opciók:
  -y, --yes       Accept safe default prompts automatically.
                  Biztonságos alapértelmezett válaszok automatikus elfogadása.
  --purge         Full uninstall: also remove Hypr-Lab-installed packages and state/backups.
                  Teljes eltávolítás: a Hypr-Lab által telepített csomagok és állapot/mentések törlése is.
  --purge-deps    Remove packages recorded as installed by Hypr-Lab.
                  A Hypr-Lab által telepítettként rögzített csomagok eltávolítása.
  --purge-state   Remove ~/.local/state/hypr-lab after uninstall.
                  A ~/.local/state/hypr-lab eltávolítása az uninstall után.
  --no-restore    Do not restore the pre-Hypr-Lab config backup; just remove Hypr-Lab files.
                  Ne állítsa vissza a Hypr-Lab előtti mentést; csak a Hypr-Lab fájlokat távolítsa el.
  --keep-login    Leave greetd/display-manager integration untouched.
                  A greetd/display-manager integráció maradjon érintetlen.
  --lang=en       Force English uninstaller language.
                  Angol eltávolítónyelv kényszerítése.
  --lang=hu       Force Hungarian uninstaller language.
                  Magyar eltávolítónyelv kényszerítése.
  -h, --help      Show this help.
                  Súgó megjelenítése.

Package removal is limited to packages recorded as missing and installed by Hypr-Lab.
Pre-existing packages are not removed.
A csomageltávolítás kizárólag a Hypr-Lab által hiányzóként és telepítettként rögzített
csomagokra korlátozódik. A korábban már meglévő csomagokat nem távolítja el.
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
    if [[ "$LANG_CHOICE" == "hu" ]]; then
        printf '%s' "$2"
    else
        printf '%s' "$1"
    fi
}

if [[ ${EUID} -eq 0 ]]; then
    say "Do not run Hypr-Lab uninstaller as root." "Ne futtasd a Hypr-Lab eltávolítót root felhasználóként."
    say "Run it as your normal user; sudo is requested only where required." "Normál felhasználóként indítsd; sudo jogosultságot csak szükség esetén kér."
    exit 1
fi

if [[ ! -f /etc/arch-release ]]; then
    say "Hypr-Lab v1.0 currently targets Arch Linux." "A Hypr-Lab v1.0 jelenleg Arch Linuxot céloz."
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
    local en="$1"
    local hu="${2:-$1}"
    if [[ "$LANG_CHOICE" == "hu" ]]; then
        printf 'FIGYELMEZTETÉS: %s\n' "$hu" >&2
    else
        printf 'WARNING: %s\n' "$en" >&2
    fi
}

ORIGINAL_BACKUP=""
if [[ -f "${STATE_DIR}/original-backup" ]]; then
    ORIGINAL_BACKUP="$(cat "${STATE_DIR}/original-backup" 2>/dev/null || true)"
fi
if [[ -n "$ORIGINAL_BACKUP" && ! -d "$ORIGINAL_BACKUP" ]]; then
    warn "Recorded original backup no longer exists: $ORIGINAL_BACKUP" "A rögzített eredeti biztonsági mentés már nem létezik: $ORIGINAL_BACKUP"
    ORIGINAL_BACKUP=""
fi

restore_file() {
    local backup_name="$1"
    local target="$2"
    mkdir -p "$(dirname "$target")"
    if (( RESTORE_BACKUP )) && [[ -n "$ORIGINAL_BACKUP" && -e "${ORIGINAL_BACKUP}/${backup_name}" ]]; then
        rm -rf "$target"
        cp -a "${ORIGINAL_BACKUP}/${backup_name}" "$target"
    else
        rm -rf "$target"
    fi
}

restore_dir() {
    local backup_name="$1"
    local target="$2"
    rm -rf "$target"
    if (( RESTORE_BACKUP )) && [[ -n "$ORIGINAL_BACKUP" && -d "${ORIGINAL_BACKUP}/${backup_name}" ]]; then
        mkdir -p "$(dirname "$target")"
        cp -a "${ORIGINAL_BACKUP}/${backup_name}" "$target"
    fi
}

restore_gsetting() {
    local key="$1"
    local file="$2"
    if ! command -v gsettings >/dev/null 2>&1; then
        return 0
    fi
    if [[ -s "${STATE_DIR}/${file}" ]]; then
        local value
        value="$(cat "${STATE_DIR}/${file}")"
        gsettings set org.gnome.desktop.interface "$key" "$value" 2>/dev/null || true
    else
        gsettings reset org.gnome.desktop.interface "$key" 2>/dev/null || true
    fi
}

echo
echo "========================================================"
if [[ "$LANG_CHOICE" == "hu" ]]; then
    echo "            HYPR-LAB ${VERSION} ELTÁVOLÍTÁS"
else
    echo "             HYPR-LAB ${VERSION} UNINSTALL"
fi
echo "========================================================"
echo
if [[ "$LANG_CHOICE" == "hu" ]]; then
    echo "Ez eltávolítja a Hypr-Lab felhasználói konfigurációját, a Hypr-Lab által kezelt"
    echo "témákat és login-integrációt. Ha van rögzített biztonsági mentés, a Hypr-Lab"
    echo "előtti konfiguráció visszaállításra kerül."
    if (( PURGE_DEPS )); then
        echo "A Hypr-Lab által telepített Arch csomagok is eltávolításra kerülnek."
    else
        echo "Az Arch csomagok megmaradnak, hacsak később nem választod a csomagtörlést."
    fi
else
    echo "This will remove Hypr-Lab user configuration, owned themes and"
    echo "Hypr-Lab login integration. Existing pre-Hypr-Lab configuration is"
    echo "restored when a recorded backup is available."
    if (( PURGE_DEPS )); then
        echo "Hypr-Lab-installed Arch packages will also be removed."
    else
        echo "Arch packages are kept unless you choose package purge later."
    fi
fi
echo

if ! confirm "$(prompt_text "Continue with Hypr-Lab uninstall?" "Folytatod a Hypr-Lab eltávolítását?")" y; then
    say "Cancelled." "Megszakítva."
    exit 0
fi

# ------------------------------------------------------------
# 1. User configuration
# ------------------------------------------------------------

echo
say "[1/6] Removing Hypr-Lab user configuration..." "[1/6] Hypr-Lab felhasználói konfiguráció eltávolítása..."
restore_dir "hypr" "${HOME}/.config/hypr"
restore_dir "quickshell" "${HOME}/.config/quickshell"
restore_file "51-hyprlab-nosuspend.conf" "${HOME}/.config/wireplumber/wireplumber.conf.d/51-hyprlab-nosuspend.conf"
restore_file "gtk3.css" "${HOME}/.config/gtk-3.0/gtk.css"
restore_file "gtk4.css" "${HOME}/.config/gtk-4.0/gtk.css"
restore_file "gtk3-settings.ini" "${HOME}/.config/gtk-3.0/settings.ini"
restore_file "gtk4-settings.ini" "${HOME}/.config/gtk-4.0/settings.ini"
restore_file "hyprlab-cursor.conf" "${HOME}/.config/environment.d/hyprlab-cursor.conf"
say "  User configuration removed/restored." "  Felhasználói konfiguráció eltávolítva/visszaállítva."

# ------------------------------------------------------------
# 2. Themes and user-installed helpers
# ------------------------------------------------------------

echo
say "[2/6] Removing Hypr-Lab-owned themes..." "[2/6] Hypr-Lab által kezelt témák eltávolítása..."
if [[ -f "${STATE_DIR}/bibata-managed" ]]; then
    rm -rf "${HOME}/.local/share/icons/Bibata-Modern-Hypr-Lab"
    say "  Removed Bibata-Modern-Hypr-Lab." "  Bibata-Modern-Hypr-Lab eltávolítva."
fi
if [[ -f "${STATE_DIR}/fluent-teal-managed" ]]; then
    rm -rf \
        "${HOME}/.local/share/icons/Fluent-teal" \
        "${HOME}/.local/share/icons/Fluent-teal-light" \
        "${HOME}/.local/share/icons/Fluent-teal-dark"
    say "  Removed Fluent teal variants installed by Hypr-Lab." "  A Hypr-Lab által telepített Fluent teal változatok eltávolítva."
fi
if [[ -f "${STATE_DIR}/clickgen-managed" ]] && command -v pipx >/dev/null 2>&1; then
    pipx uninstall clickgen >/dev/null 2>&1 || true
    say "  Removed Hypr-Lab-installed clickgen environment." "  A Hypr-Lab által telepített clickgen környezet eltávolítva."
fi

restore_gsetting cursor-theme previous-cursor-theme
restore_gsetting cursor-size previous-cursor-size
restore_gsetting icon-theme previous-icon-theme

# ------------------------------------------------------------
# 3. Login manager
# ------------------------------------------------------------

echo
say "[3/6] Restoring login-manager state..." "[3/6] Login manager állapotának visszaállítása..."
if (( KEEP_LOGIN )); then
    say "  Login-manager integration kept by request." "  A login-manager integráció kérésre érintetlen maradt."
elif [[ -f "${STATE_DIR}/greetd-managed" ]]; then
    sudo systemctl disable greetd.service >/dev/null 2>&1 || true

    if (( RESTORE_BACKUP )) && [[ -n "$ORIGINAL_BACKUP" && -f "${ORIGINAL_BACKUP}/greetd-config.toml" ]]; then
        sudo install -Dm644 "${ORIGINAL_BACKUP}/greetd-config.toml" /etc/greetd/config.toml
        say "  Restored previous greetd configuration." "  Korábbi greetd konfiguráció visszaállítva."
    else
        sudo rm -f /etc/greetd/config.toml
        say "  Removed Hypr-Lab greetd configuration." "  Hypr-Lab greetd konfiguráció eltávolítva."
    fi

    if [[ -f "${STATE_DIR}/greetd-was-enabled" ]]; then
        sudo systemctl enable greetd.service >/dev/null 2>&1 || true
        say "  Re-enabled pre-existing greetd service." "  A korábban meglévő greetd szolgáltatás újra engedélyezve."
    fi

    if [[ -s "${STATE_DIR}/previous-display-manager" ]]; then
        previous_dm="$(cat "${STATE_DIR}/previous-display-manager")"
        if [[ -n "$previous_dm" ]]; then
            sudo systemctl enable "$previous_dm" >/dev/null 2>&1 || true
            say "  Re-enabled previous display manager: $previous_dm" "  Korábbi display manager újra engedélyezve: $previous_dm"
        fi
    fi
else
    say "  No Hypr-Lab-managed greetd state recorded." "  Nincs rögzített, Hypr-Lab által kezelt greetd állapot."
fi

# ------------------------------------------------------------
# 4. Packages
# ------------------------------------------------------------

echo
say "[4/6] Package cleanup..." "[4/6] Csomagok takarítása..."
if (( ! PURGE_DEPS )); then
    if [[ -s "${STATE_DIR}/installed-packages.txt" ]] && confirm "$(prompt_text "Remove Arch packages that Hypr-Lab installed?" "Eltávolítod a Hypr-Lab által telepített Arch csomagokat?")" n; then
        PURGE_DEPS=1
    fi
fi

if (( PURGE_DEPS )); then
    if [[ ! -s "${STATE_DIR}/installed-packages.txt" ]]; then
        warn "No managed-package record exists; refusing unsafe dependency removal." "Nincs kezelt csomaglista; a nem biztonságos függőségeltávolítás megtagadva."
        warn "Hypr-Lab files are removed, but packages are being kept." "A Hypr-Lab fájljai eltávolításra kerülnek, de a csomagok megmaradnak."
    else
        mapfile -t recorded_packages < "${STATE_DIR}/installed-packages.txt"
        installed_packages=()
        for pkg in "${recorded_packages[@]}"; do
            [[ -n "$pkg" ]] || continue
            if pacman -Q "$pkg" >/dev/null 2>&1; then
                installed_packages+=("$pkg")
            fi
        done

        if ((${#installed_packages[@]})); then
            say "  Packages recorded as installed by Hypr-Lab:" "  Hypr-Lab által telepítettként rögzített csomagok:"
            printf '    • %s\n' "${installed_packages[@]}"
            echo
            if (( PURGE_DEPS )) && { (( ASSUME_YES )) || confirm "$(prompt_text "Remove these packages with pacman -Rns?" "Eltávolítod ezeket a csomagokat pacman -Rns használatával?")" y; }; then
                if (( ASSUME_YES )); then
                    sudo pacman -Rns --noconfirm -- "${installed_packages[@]}" || warn "pacman refused some removals because other packages need them." "A pacman néhány eltávolítást megtagadott, mert más csomagoknak szükségük van rájuk."
                else
                    sudo pacman -Rns -- "${installed_packages[@]}" || warn "pacman refused some removals because other packages need them." "A pacman néhány eltávolítást megtagadott, mert más csomagoknak szükségük van rájuk."
                fi
            fi
        else
            say "  No recorded Hypr-Lab-installed packages remain installed." "  Egyetlen Hypr-Lab által telepítettként rögzített csomag sincs már telepítve."
        fi
    fi
else
    say "  Package removal skipped." "  Csomageltávolítás kihagyva."
fi

# ------------------------------------------------------------
# 5. State/backups
# ------------------------------------------------------------

echo
say "[5/6] Hypr-Lab state..." "[5/6] Hypr-Lab állapotfájlok..."
if (( ! PURGE_STATE )) && [[ -d "$STATE_DIR" ]]; then
    if confirm "$(prompt_text "Remove Hypr-Lab backups and installer state too?" "Eltávolítod a Hypr-Lab biztonsági mentéseit és telepítőállapotát is?")" n; then
        PURGE_STATE=1
    fi
fi

if (( PURGE_STATE )); then
    rm -rf "$STATE_DIR"
    say "  Removed $STATE_DIR" "  Eltávolítva: $STATE_DIR"
else
    say "  Backups/state kept at $STATE_DIR" "  Biztonsági mentések/állapot megőrizve itt: $STATE_DIR"
fi

# ------------------------------------------------------------
# 6. Finish
# ------------------------------------------------------------

echo
say "[6/6] Uninstall complete." "[6/6] Eltávolítás kész."
echo
say "Hypr-Lab files have been removed." "A Hypr-Lab fájljai eltávolításra kerültek."
if (( PURGE_DEPS )); then
    say "Recorded Hypr-Lab-installed packages were offered for removal." "A Hypr-Lab által telepítettként rögzített csomagok eltávolítása fel lett ajánlva."
else
    say "Installed Arch packages were kept. Use './uninstall.sh --purge' for a full recorded-package purge." "A telepített Arch csomagok megmaradtak. A teljes rögzített csomageltávolításhoz használd: './uninstall.sh --purge'."
fi
echo
say "Log out or reboot before starting another desktop session." "Jelentkezz ki vagy indítsd újra a gépet, mielőtt másik asztali munkamenetet indítasz."
say "The Git clone/release directory itself is not deleted; remove it manually if desired." "A Git clone/release könyvtárat az eltávolító nem törli; igény esetén kézzel távolítsd el."
