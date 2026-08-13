#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0-rc3"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_DIR="${STATE_HOME}/hypr-lab"

ASSUME_YES=0
PURGE_DEPS=0
PURGE_STATE=0
RESTORE_BACKUP=1
KEEP_LOGIN=0

for arg in "$@"; do
    case "$arg" in
        -y|--yes) ASSUME_YES=1 ;;
        --purge) PURGE_DEPS=1; PURGE_STATE=1 ;;
        --purge-deps) PURGE_DEPS=1 ;;
        --purge-state) PURGE_STATE=1 ;;
        --no-restore) RESTORE_BACKUP=0 ;;
        --keep-login) KEEP_LOGIN=1 ;;
        -h|--help)
            cat <<EOH
Hypr-Lab ${VERSION} uninstaller

Usage:
  ./uninstall.sh [options]

Default behavior removes Hypr-Lab configuration, themes and login integration,
then offers to remove packages that were installed by Hypr-Lab.

Options:
  -y, --yes       Accept safe default prompts automatically.
  --purge         Full uninstall: also remove Hypr-Lab-installed packages and state/backups.
  --purge-deps    Remove packages recorded as installed by Hypr-Lab.
  --purge-state   Remove ~/.local/state/hypr-lab after uninstall.
  --no-restore    Do not restore the pre-Hypr-Lab config backup; just remove Hypr-Lab files.
  --keep-login    Leave greetd/display-manager integration untouched.
  -h, --help      Show this help.

Package removal is intentionally limited to packages that the RC3 installer
recorded as missing and installed itself. Pre-existing packages are not removed.
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
    echo "Do not run Hypr-Lab uninstaller as root."
    echo "Run it as your normal user; sudo is requested only where required."
    exit 1
fi

if [[ ! -f /etc/arch-release ]]; then
    echo "Hypr-Lab v1.0 currently targets Arch Linux."
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

ORIGINAL_BACKUP=""
if [[ -f "${STATE_DIR}/original-backup" ]]; then
    ORIGINAL_BACKUP="$(cat "${STATE_DIR}/original-backup" 2>/dev/null || true)"
fi
if [[ -n "$ORIGINAL_BACKUP" && ! -d "$ORIGINAL_BACKUP" ]]; then
    warn "Recorded original backup no longer exists: $ORIGINAL_BACKUP"
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
echo "             HYPR-LAB ${VERSION} UNINSTALL"
echo "========================================================"
echo
echo "This will remove Hypr-Lab user configuration, owned themes and"
echo "Hypr-Lab login integration. Existing pre-Hypr-Lab configuration is"
echo "restored when a recorded backup is available."
if (( PURGE_DEPS )); then
    echo "Hypr-Lab-installed Arch packages will also be removed."
else
    echo "Arch packages are kept unless you choose package purge later."
fi
echo

if ! confirm "Continue with Hypr-Lab uninstall?" y; then
    echo "Cancelled."
    exit 0
fi

# ------------------------------------------------------------
# 1. User configuration
# ------------------------------------------------------------

echo
echo "[1/6] Removing Hypr-Lab user configuration..."
restore_dir "hypr" "${HOME}/.config/hypr"
restore_dir "quickshell" "${HOME}/.config/quickshell"
restore_file "51-hyprlab-nosuspend.conf" "${HOME}/.config/wireplumber/wireplumber.conf.d/51-hyprlab-nosuspend.conf"
restore_file "gtk3.css" "${HOME}/.config/gtk-3.0/gtk.css"
restore_file "gtk4.css" "${HOME}/.config/gtk-4.0/gtk.css"
restore_file "gtk3-settings.ini" "${HOME}/.config/gtk-3.0/settings.ini"
restore_file "gtk4-settings.ini" "${HOME}/.config/gtk-4.0/settings.ini"
restore_file "hyprlab-cursor.conf" "${HOME}/.config/environment.d/hyprlab-cursor.conf"
echo "  User configuration removed/restored."

# ------------------------------------------------------------
# 2. Themes and user-installed helpers
# ------------------------------------------------------------

echo
echo "[2/6] Removing Hypr-Lab-owned themes..."
if [[ -f "${STATE_DIR}/bibata-managed" ]]; then
    rm -rf "${HOME}/.local/share/icons/Bibata-Modern-Hypr-Lab"
    echo "  Removed Bibata-Modern-Hypr-Lab."
fi
if [[ -f "${STATE_DIR}/fluent-teal-managed" ]]; then
    rm -rf \
        "${HOME}/.local/share/icons/Fluent-teal" \
        "${HOME}/.local/share/icons/Fluent-teal-light" \
        "${HOME}/.local/share/icons/Fluent-teal-dark"
    echo "  Removed Fluent teal variants installed by Hypr-Lab."
fi
if [[ -f "${STATE_DIR}/clickgen-managed" ]] && command -v pipx >/dev/null 2>&1; then
    pipx uninstall clickgen >/dev/null 2>&1 || true
    echo "  Removed Hypr-Lab-installed clickgen environment."
fi

restore_gsetting cursor-theme previous-cursor-theme
restore_gsetting cursor-size previous-cursor-size
restore_gsetting icon-theme previous-icon-theme

# ------------------------------------------------------------
# 3. Login manager
# ------------------------------------------------------------

echo
echo "[3/6] Restoring login-manager state..."
if (( KEEP_LOGIN )); then
    echo "  Login-manager integration kept by request."
elif [[ -f "${STATE_DIR}/greetd-managed" ]]; then
    sudo systemctl disable greetd.service >/dev/null 2>&1 || true

    if (( RESTORE_BACKUP )) && [[ -n "$ORIGINAL_BACKUP" && -f "${ORIGINAL_BACKUP}/greetd-config.toml" ]]; then
        sudo install -Dm644 "${ORIGINAL_BACKUP}/greetd-config.toml" /etc/greetd/config.toml
        echo "  Restored previous greetd configuration."
    else
        sudo rm -f /etc/greetd/config.toml
        echo "  Removed Hypr-Lab greetd configuration."
    fi

    if [[ -f "${STATE_DIR}/greetd-was-enabled" ]]; then
        sudo systemctl enable greetd.service >/dev/null 2>&1 || true
        echo "  Re-enabled pre-existing greetd service."
    fi

    if [[ -s "${STATE_DIR}/previous-display-manager" ]]; then
        previous_dm="$(cat "${STATE_DIR}/previous-display-manager")"
        if [[ -n "$previous_dm" ]]; then
            sudo systemctl enable "$previous_dm" >/dev/null 2>&1 || true
            echo "  Re-enabled previous display manager: $previous_dm"
        fi
    fi
else
    echo "  No Hypr-Lab-managed greetd state recorded."
fi

# ------------------------------------------------------------
# 4. Packages
# ------------------------------------------------------------

echo
echo "[4/6] Package cleanup..."
if (( ! PURGE_DEPS )); then
    if [[ -s "${STATE_DIR}/installed-packages.txt" ]] && confirm "Remove Arch packages that Hypr-Lab installed?" n; then
        PURGE_DEPS=1
    fi
fi

if (( PURGE_DEPS )); then
    if [[ ! -s "${STATE_DIR}/installed-packages.txt" ]]; then
        warn "No RC3 managed-package record exists; refusing unsafe dependency removal."
        warn "Hypr-Lab files are removed, but packages are being kept."
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
            echo "  Packages recorded as installed by Hypr-Lab:"
            printf '    • %s\n' "${installed_packages[@]}"
            echo
            if (( PURGE_DEPS )) && { (( ASSUME_YES )) || confirm "Remove these packages with pacman -Rns?" y; }; then
                if (( ASSUME_YES )); then
                    sudo pacman -Rns --noconfirm -- "${installed_packages[@]}" || warn "pacman refused some removals because other packages need them."
                else
                    sudo pacman -Rns -- "${installed_packages[@]}" || warn "pacman refused some removals because other packages need them."
                fi
            fi
        else
            echo "  No recorded Hypr-Lab-installed packages remain installed."
        fi
    fi
else
    echo "  Package removal skipped."
fi

# ------------------------------------------------------------
# 5. State/backups
# ------------------------------------------------------------

echo
echo "[5/6] Hypr-Lab state..."
if (( ! PURGE_STATE )) && [[ -d "$STATE_DIR" ]]; then
    if confirm "Remove Hypr-Lab backups and installer state too?" n; then
        PURGE_STATE=1
    fi
fi

if (( PURGE_STATE )); then
    rm -rf "$STATE_DIR"
    echo "  Removed $STATE_DIR"
else
    echo "  Backups/state kept at $STATE_DIR"
fi

# ------------------------------------------------------------
# 6. Finish
# ------------------------------------------------------------

echo
echo "[6/6] Uninstall complete."
echo
echo "Hypr-Lab files have been removed."
if (( PURGE_DEPS )); then
    echo "Recorded Hypr-Lab-installed packages were offered for removal."
else
    echo "Installed Arch packages were kept. Use './uninstall.sh --purge' for a full recorded-package purge."
fi
echo
echo "Log out or reboot before starting another desktop session."
echo "The Git clone/release directory itself is not deleted; remove it manually if desired."
