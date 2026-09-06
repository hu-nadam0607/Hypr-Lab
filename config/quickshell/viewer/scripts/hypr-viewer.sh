#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
viewer_dir="$(cd -- "${script_dir}/.." && pwd)"

input_json="$(
    python3 - "$@" <<'PY'
import json
import os
import sys
from urllib.parse import unquote, urlparse

items = []

for raw in sys.argv[1:]:
    value = raw

    if value.startswith("file://"):
        value = unquote(urlparse(value).path)

    path = os.path.abspath(os.path.expanduser(value))

    if os.path.isdir(path):
        items.append({"kind": "directory", "path": path})
    elif os.path.isfile(path):
        items.append({"kind": "file", "path": path})

print(json.dumps(items, ensure_ascii=False))
PY
)"

exec env \
    HYPR_VIEWER_INPUT="${input_json}" \
    quickshell -p "${viewer_dir}"
