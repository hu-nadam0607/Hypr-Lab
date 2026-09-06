#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
viewer_dir="$(cd -- "${script_dir}/.." && pwd)"

data_home="${XDG_DATA_HOME:-${HOME}/.local/share}"
applications_dir="${data_home}/applications"
desktop_file="${applications_dir}/hypr-lab-viewer.desktop"

launcher="${viewer_dir}/scripts/hypr-viewer.sh"
icon="${viewer_dir}/assets/hypr-lab-viewer.svg"

mkdir -p "${applications_dir}"
chmod +x "${launcher}"

cat > "${desktop_file}" <<EOF_DESKTOP
[Desktop Entry]
Type=Application
Version=1.0
Name=Hypr-Viewer
GenericName=Image Viewer
Comment=Hypr-Lab image viewer
Exec=${launcher} %F
TryExec=${launcher}
Icon=${icon}
Terminal=false
Categories=Graphics;Viewer;
MimeType=image/png;image/jpeg;image/webp;image/bmp;image/x-bmp;image/gif;
StartupWMClass=hypr-lab-viewer
DBusActivatable=false
NoDisplay=false
EOF_DESKTOP

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${applications_dir}" >/dev/null 2>&1 || true
fi

mime_types=(
    image/png
    image/jpeg
    image/webp
    image/bmp
    image/x-bmp
    image/gif
)

for mime in "${mime_types[@]}"; do
    xdg-mime default hypr-lab-viewer.desktop "${mime}"
done

printf 'Hypr-Viewer integration installed.\n'
printf '  Desktop entry: %s\n' "${desktop_file}"
printf '  Icon:          %s\n' "${icon}"
