#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

fail=0

LANG_CHOICE=""
case "${LANG:-}" in
    hu_HU*|hu*) LANG_CHOICE="hu" ;;
    *) LANG_CHOICE="en" ;;
esac

for arg in "$@"; do
    case "$arg" in
        --lang=hu) LANG_CHOICE="hu" ;;
        --lang=en) LANG_CHOICE="en" ;;
        -h|--help)
            cat <<'EOH'
Hypr-Lab release verifier / release-ellenőrző

Usage / Használat:
  ./verify-release.sh [options]

Options / Opciók:
  --lang=en    Force English output.
               Angol kimenet kényszerítése.
  --lang=hu    Force Hungarian output.
               Magyar kimenet kényszerítése.
  -h, --help   Show this help.
               Súgó megjelenítése.
EOH
            exit 0
            ;;
        *)
            printf 'Unknown option / Ismeretlen opció: %s\n' "$arg" >&2
            exit 2
            ;;
    esac
done

say() {
    local en="$1"
    local hu="$2"
    if [[ "$LANG_CHOICE" == "hu" ]]; then
        printf '%s\n' "$hu"
    else
        printf '%s\n' "$en"
    fi
}

check_absent() {
    local pattern="$1"
    local label_en="$2"
    local label_hu="$3"
    if grep -RniE "$pattern" "$ROOT" \
        --exclude='README.md' \
        --exclude='THIRD_PARTY_NOTICES.md' \
        --exclude='verify-release.sh' >/tmp/hyprlab-verify.$$ 2>/dev/null; then
        if [[ "$LANG_CHOICE" == "hu" ]]; then
            echo "HIBA: $label_hu"
        else
            echo "FAIL: $label_en"
        fi
        cat /tmp/hyprlab-verify.$$
        fail=1
    else
        if [[ "$LANG_CHOICE" == "hu" ]]; then
            echo "OK:   $label_hu"
        else
            echo "OK:   $label_en"
        fi
    fi
    rm -f /tmp/hyprlab-verify.$$
}

bash -n "$ROOT/install.sh"
bash -n "$ROOT/uninstall.sh"
find "$ROOT/config/hypr" -type f -name '*.sh' -print0 | xargs -0 -r -n1 bash -n

say "OK:   installer/uninstaller shell syntax" "OK:   installer/uninstaller shell szintaxis"
check_absent '/home/[A-Za-z0-9_-]+' 'no hardcoded /home/<user> paths' 'nincs hardcode-olt /home/<user> útvonal'
check_absent 'volume-notify|toggle-border-anim' 'no obsolete helper references' 'nincs elavult helper-hivatkozás'
if grep -Rni 'XRAY' "$ROOT/config/quickshell" "$ROOT/config/hypr/hyprlab-scripts" >/tmp/hyprlab-verify.$$ 2>/dev/null; then
    say "FAIL: obsolete Settings XRAY backend key remains" "HIBA: elavult Settings XRAY backend kulcs maradt a release-ben"
    cat /tmp/hyprlab-verify.$$
    fail=1
else
    say "OK:   no obsolete Settings XRAY backend key" "OK:   nincs elavult Settings XRAY backend kulcs"
fi
rm -f /tmp/hyprlab-verify.$$

if find "$ROOT" -name '.welcome-disabled' -print -quit | grep -q .; then
    say "FAIL: release contains .welcome-disabled" "HIBA: a release .welcome-disabled fájlt tartalmaz"
    fail=1
else
    say "OK:   Welcome state is release-clean" "OK:   a Welcome állapot release-clean"
fi

if grep -q '__HYPRLAB_KB_LAYOUT__' "$ROOT/config/hypr/hyprland.lua"; then
    say "OK:   keyboard layout placeholder" "OK:   billentyűzetkiosztás-placeholder jelen van"
else
    say "FAIL: keyboard layout placeholder missing" "HIBA: hiányzik a billentyűzetkiosztás-placeholder"
    fail=1
fi

if [[ "$(cat "$ROOT/config/hypr/hyprlab-settings/monitors.json")" == '[]' ]]; then
    say "OK:   monitor state is clean" "OK:   a monitor state tiszta"
else
    say "FAIL: monitor state is not []" "HIBA: a monitor state nem []"
    fail=1
fi

if grep -q 'hl.exec_cmd("quickshell")' "$ROOT/config/hypr/hyprland.lua"; then
    say "OK:   Quickshell autostart present" "OK:   Quickshell autostart jelen van"
else
    say "FAIL: Quickshell autostart missing" "HIBA: hiányzik a Quickshell autostart"
    fail=1
fi

if grep -q 'VERSION="1.0.0"' "$ROOT/install.sh" && grep -q 'VERSION="1.0.0"' "$ROOT/uninstall.sh"; then
    say "OK:   stable 1.0 script versions" "OK:   stabil 1.0 scriptverziók"
else
    say "FAIL: stable 1.0 script version mismatch" "HIBA: az stabil 1.0 scriptverziók nem egyeznek"
    fail=1
fi

if grep -q 'record_managed_packages' "$ROOT/install.sh" && grep -q 'installed-packages.txt' "$ROOT/uninstall.sh"; then
    say "OK:   tracked dependency uninstall path" "OK:   nyomon követett függőség-eltávolítási útvonal"
else
    say "FAIL: tracked dependency uninstall path incomplete" "HIBA: a nyomon követett függőség-eltávolítási útvonal hiányos"
    fail=1
fi

exit "$fail"
