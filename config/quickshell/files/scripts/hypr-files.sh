#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
files_dir="$(cd -- "${script_dir}/.." && pwd)"

data_home="${XDG_DATA_HOME:-${HOME}/.local/share}"
desktop_file="${data_home}/applications/hypr-lab-files.desktop"

# The Quickshell AppId pragma is "hypr-lab-files". Qt's portal integration
# expects a matching desktop entry to exist when the application starts.
if [[ ! -f "${desktop_file}" ]] || ! grep -q "^Exec=${files_dir}/scripts/hypr-files.sh %U$" "${desktop_file}" 2>/dev/null; then
    "${script_dir}/hypr-files-register.sh" --quiet
fi

start_path="${1:-${HOME}}"
if [[ "${start_path}" == file://* ]]; then
    start_path="$(python3 - "${start_path}" <<'PY'
import sys
from urllib.parse import unquote, urlparse
print(unquote(urlparse(sys.argv[1]).path))
PY
)"
fi
start_path="$(python3 - "${start_path}" <<'PY'
import os, sys
p = os.path.abspath(os.path.expanduser(sys.argv[1]))
if os.path.isfile(p):
    p = os.path.dirname(p)
print(p)
PY
)"

# Internal mode: Hyprland has already attached the static launch rules to this
# process. Start Quickshell directly and keep the PID chain intact so the rules
# are applied before the Wayland toplevel is mapped.
if [[ "${HYPR_FILES_RULED_LAUNCH:-0}" == "1" ]]; then
    exec env \
        HYPR_FILES_DIR="${files_dir}" \
        HYPR_FILES_START_PATH="${start_path}" \
        quickshell -p "${files_dir}"
fi

# Under Hyprland, launch through the compositor's exec_cmd dispatcher with
# *static* float + center rules. This is intentionally different from the old
# watcher approach: the window is born floating and centered, so the current
# tiled layout is never temporarily reflowed and there is no corner-to-center
# jump/animation.
if command -v hyprctl >/dev/null 2>&1 && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    ruled_cmd="$(printf '%q ' env HYPR_FILES_RULED_LAUNCH=1 "${script_dir}/hypr-files.sh" "${start_path}")"

    lua_cmd="$(python3 - "${ruled_cmd}" <<'PY'
import json, sys
cmd = sys.argv[1].rstrip()
# JSON string quoting is valid for the normal characters used by shell command
# paths and safely protects spaces, quotes and non-ASCII path names here.
quoted = json.dumps(cmd, ensure_ascii=False)
print(f'hl.dsp.exec_cmd({quoted}, {{ float = true, center = true }})')
PY
)"

    if hyprctl dispatch "${lua_cmd}" >/dev/null; then
        exit 0
    fi
fi

# Fallback for non-Hyprland sessions or if IPC is unavailable. Quickshell can
# still run, but compositor-specific initial floating cannot be guaranteed.
exec env \
    HYPR_FILES_DIR="${files_dir}" \
    HYPR_FILES_START_PATH="${start_path}" \
    quickshell -p "${files_dir}"
