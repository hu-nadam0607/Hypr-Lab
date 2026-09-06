#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
files_dir="$(cd -- "${script_dir}/.." && pwd)"

data_home="${XDG_DATA_HOME:-${HOME}/.local/share}"
applications_dir="${data_home}/applications"
desktop_file="${applications_dir}/hypr-lab-files.desktop"
launcher="${files_dir}/scripts/hypr-files.sh"
icon="${files_dir}/assets/hypr-lab-files.svg"

quiet=false
set_default=false
for arg in "$@"; do
    case "$arg" in
        --quiet) quiet=true ;;
        --set-default) set_default=true ;;
    esac
done

mkdir -p "${applications_dir}"
chmod +x "${launcher}" "${files_dir}/scripts/hypr-files-backend.py" "${files_dir}/scripts/hypr-files-register.sh"

cat > "${desktop_file}" <<EOF_DESKTOP
[Desktop Entry]
Type=Application
Version=1.0
Name=Hypr-Files
GenericName=File Manager
Comment=Hypr-Lab file manager
Exec=${launcher} %U
TryExec=${launcher}
Icon=${icon}
Terminal=false
Categories=System;FileTools;FileManager;
MimeType=inode/directory;
StartupWMClass=hypr-lab-files
DBusActivatable=false
NoDisplay=false
Keywords=files;folders;manager;explorer;
EOF_DESKTOP

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${applications_dir}" >/dev/null 2>&1 || true
fi

if [[ "${set_default}" == true ]]; then
    xdg-mime default hypr-lab-files.desktop inode/directory
    # Hypr-Lab uses a Lua Hyprland configuration. Super+E is defined there,
    # not in a generated .conf fragment. Remove the legacy fragment from older hotfixes.
    rm -f "${HOME}/.config/hypr/hyprlab-files.conf"
fi

if [[ "${quiet}" != true ]]; then
    if [[ "${set_default}" == true ]]; then
        printf 'Hypr-Files is now the default directory handler.\n'
        printf 'Directory MIME default set to Hypr-Files. Super+E is configured in Hypr-Lab hyprland.lua.\n'
    fi
    printf 'Hypr-Files integration installed.\n'
    printf '  Desktop entry: %s\n' "${desktop_file}"
    printf '  Icon:          %s\n' "${icon}"
    printf '  Launcher:      %s\n' "${launcher}"
fi
