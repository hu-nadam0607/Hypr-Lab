#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

fail=0

check_absent() {
    local pattern="$1"
    local label="$2"
    if grep -RniE "$pattern" "$ROOT" \
        --exclude='README.md' \
        --exclude='THIRD_PARTY_NOTICES.md' \
        --exclude='verify-release.sh' >/tmp/hyprlab-verify.$$ 2>/dev/null; then
        echo "FAIL: $label"
        cat /tmp/hyprlab-verify.$$
        fail=1
    else
        echo "OK:   $label"
    fi
    rm -f /tmp/hyprlab-verify.$$
}

bash -n "$ROOT/install.sh"
bash -n "$ROOT/uninstall.sh"
find "$ROOT/config/hypr" -type f -name '*.sh' -print0 | xargs -0 -r -n1 bash -n

echo "OK:   installer/uninstaller shell syntax"
check_absent '/home/[A-Za-z0-9_-]+' 'no hardcoded /home/<user> paths'
check_absent 'volume-notify|toggle-border-anim' 'no obsolete helper references'
if grep -Rni 'XRAY' "$ROOT/config/quickshell" "$ROOT/config/hypr/hyprlab-scripts" >/tmp/hyprlab-verify.$$ 2>/dev/null; then
    echo "FAIL: obsolete Settings XRAY backend key remains"
    cat /tmp/hyprlab-verify.$$
    fail=1
else
    echo "OK:   no obsolete Settings XRAY backend key"
fi
rm -f /tmp/hyprlab-verify.$$

if find "$ROOT" -name '.welcome-disabled' -print -quit | grep -q .; then
    echo "FAIL: release contains .welcome-disabled"
    fail=1
else
    echo "OK:   Welcome state is release-clean"
fi

if grep -q '__HYPRLAB_KB_LAYOUT__' "$ROOT/config/hypr/hyprland.lua"; then
    echo "OK:   keyboard layout placeholder"
else
    echo "FAIL: keyboard layout placeholder missing"
    fail=1
fi

if [[ "$(cat "$ROOT/config/hypr/hyprlab-settings/monitors.json")" == '[]' ]]; then
    echo "OK:   monitor state is clean"
else
    echo "FAIL: monitor state is not []"
    fail=1
fi

if grep -q 'hl.exec_cmd("quickshell")' "$ROOT/config/hypr/hyprland.lua"; then
    echo "OK:   Quickshell autostart present"
else
    echo "FAIL: Quickshell autostart missing"
    fail=1
fi

if grep -q 'VERSION="1.0.0-rc3"' "$ROOT/install.sh" && grep -q 'VERSION="1.0.0-rc3"' "$ROOT/uninstall.sh"; then
    echo "OK:   RC3 script versions"
else
    echo "FAIL: RC3 script version mismatch"
    fail=1
fi

if grep -q 'record_managed_packages' "$ROOT/install.sh" && grep -q 'installed-packages.txt' "$ROOT/uninstall.sh"; then
    echo "OK:   tracked dependency uninstall path"
else
    echo "FAIL: tracked dependency uninstall path incomplete"
    fail=1
fi

exit "$fail"
