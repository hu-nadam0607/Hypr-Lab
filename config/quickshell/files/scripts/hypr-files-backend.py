#!/usr/bin/env python3
from __future__ import annotations

import configparser
import json
import mimetypes
import os
import re
import signal
import shlex
import shutil
import stat
import subprocess
import sys
import time
from pathlib import Path
from urllib.parse import quote

HOME = Path.home()
XDG_CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", HOME / ".config"))
XDG_DATA = Path(os.environ.get("XDG_DATA_HOME", HOME / ".local/share"))
FAVORITES_FILE = XDG_CONFIG / "quickshell" / "files" / "favorites.json"


class OperationCancelled(Exception):
    pass


CURRENT_PARTIAL = None


def _sigterm_handler(signum, frame):
    raise OperationCancelled("Operation cancelled")

signal.signal(signal.SIGTERM, _sigterm_handler)

def cleanup_partial():
    global CURRENT_PARTIAL
    p = CURRENT_PARTIAL
    CURRENT_PARTIAL = None
    if not p:
        return
    try:
        p = Path(p)
        if p.is_dir() and not p.is_symlink():
            shutil.rmtree(p, ignore_errors=True)
        else:
            p.unlink(missing_ok=True)
    except Exception:
        pass


def out(value):
    print(json.dumps(value, ensure_ascii=False), flush=True)


def progress(operation: str, percent: int, detail: str = ""):
    out({"event": "progress", "operation": operation, "percent": max(0, min(100, int(percent))), "detail": detail})


def path_weight(path: Path) -> int:
    """Return a cheap byte-like work estimate for progress reporting."""
    try:
        if path.is_symlink():
            return 1
        if path.is_file():
            return max(1, path.stat().st_size)
        if path.is_dir():
            total = 0
            for root, dirs, files in os.walk(path, followlinks=False):
                rootp = Path(root)
                for name in files:
                    try:
                        fp = rootp / name
                        total += 1 if fp.is_symlink() else max(1, fp.stat().st_size)
                    except OSError:
                        total += 1
                for name in dirs:
                    try:
                        if (rootp / name).is_symlink():
                            total += 1
                    except OSError:
                        pass
            return max(1, total)
    except OSError:
        pass
    return 1


class ProgressReporter:
    def __init__(self, operation: str, total: int):
        self.operation = operation
        self.total = max(1, int(total))
        self.done = 0
        self.last_percent = -1
        self.emit(0)

    def emit(self, percent=None, detail=""):
        if percent is None:
            percent = int((self.done * 100) / self.total)
        percent = max(0, min(100, int(percent)))
        if percent != self.last_percent or detail:
            progress(self.operation, percent, detail)
            self.last_percent = percent

    def add(self, amount: int, detail=""):
        self.done = min(self.total, self.done + max(0, int(amount)))
        self.emit(detail=detail)

    def finish(self, detail=""):
        self.done = self.total
        self.emit(100, detail)


def copy_file_progress(src: Path, dst: Path, reporter: ProgressReporter):
    if src.is_symlink():
        os.symlink(os.readlink(src), dst)
        reporter.add(1, src.name)
        return
    size = max(1, src.stat().st_size)
    copied = 0
    with src.open("rb") as rf, dst.open("wb") as wf:
        while True:
            chunk = rf.read(1024 * 1024)
            if not chunk:
                break
            wf.write(chunk)
            copied += len(chunk)
            reporter.add(len(chunk), src.name)
    if copied == 0:
        reporter.add(size, src.name)
    elif copied < size:
        reporter.add(size - copied, src.name)
    shutil.copystat(src, dst, follow_symlinks=False)


def copy_tree_progress(src: Path, dst: Path, reporter: ProgressReporter):
    if src.is_symlink():
        os.symlink(os.readlink(src), dst)
        reporter.add(1, src.name)
        return
    if src.is_file():
        copy_file_progress(src, dst, reporter)
        return
    dst.mkdir(parents=True, exist_ok=False)
    for entry in os.scandir(src):
        ep = Path(entry.path)
        target = dst / entry.name
        if ep.is_dir() and not ep.is_symlink():
            copy_tree_progress(ep, target, reporter)
        else:
            copy_file_progress(ep, target, reporter)
    shutil.copystat(src, dst, follow_symlinks=False)


def human_size(size: int) -> str:
    units = ["B", "KiB", "MiB", "GiB", "TiB"]
    value = float(size)
    for unit in units:
        if value < 1024 or unit == units[-1]:
            return f"{int(value)} {unit}" if unit == "B" else f"{value:.1f} {unit}"
        value /= 1024
    return f"{size} B"


def mime_for(path: Path) -> str:
    guessed, _ = mimetypes.guess_type(str(path))
    if guessed:
        return guessed
    try:
        proc = subprocess.run(
            ["file", "--brief", "--mime-type", "--", str(path)],
            text=True,
            capture_output=True,
            timeout=2,
            check=False,
        )
        value = proc.stdout.strip()
        return value or "application/octet-stream"
    except Exception:
        return "application/octet-stream"


def info_for(path: Path) -> dict:
    try:
        st = path.lstat()
    except OSError:
        return {}
    is_dir = stat.S_ISDIR(st.st_mode)
    name = path.name or str(path)
    mime = "inode/directory" if is_dir else mime_for(path)
    return {
        "name": name,
        "path": str(path),
        "url": "file://" + quote(str(path)),
        "isDir": is_dir,
        "isFile": stat.S_ISREG(st.st_mode),
        "isSymlink": path.is_symlink(),
        "size": st.st_size,
        "sizeHuman": "—" if is_dir else human_size(st.st_size),
        "mtime": int(st.st_mtime),
        "mtimeText": time.strftime("%Y-%m-%d %H:%M", time.localtime(st.st_mtime)),
        "mime": mime,
        "ext": path.suffix[1:].lower(),
        "hidden": name.startswith("."),
        "readable": os.access(path, os.R_OK),
        "writable": os.access(path, os.W_OK),
    }


def cmd_list(argv):
    path = Path(argv[0] if argv else HOME).expanduser().resolve()
    show_hidden = len(argv) > 1 and argv[1] == "1"
    sort_key = argv[2] if len(argv) > 2 else "name"
    descending = len(argv) > 3 and argv[3] == "1"
    folders_first = len(argv) <= 4 or argv[4] == "1"

    items = []
    try:
        for entry in os.scandir(path):
            if not show_hidden and entry.name.startswith("."):
                continue
            item = info_for(Path(entry.path))
            if item:
                items.append(item)
    except OSError as exc:
        out({"ok": False, "error": str(exc), "path": str(path), "items": []})
        return

    def key(item):
        if sort_key == "size":
            main = item["size"]
        elif sort_key == "mtime":
            main = item["mtime"]
        elif sort_key == "type":
            main = (item["mime"].lower(), item["name"].lower())
        else:
            main = item["name"].lower()
        prefix = 0 if item["isDir"] else 1
        return (prefix, main) if folders_first else main

    items.sort(key=key, reverse=descending)
    # Keep directories first even in descending mode.
    if folders_first:
        dirs = [x for x in items if x["isDir"]]
        files = [x for x in items if not x["isDir"]]
        dirs.sort(key=lambda x: key(x)[1], reverse=descending)
        files.sort(key=lambda x: key(x)[1], reverse=descending)
        items = dirs + files

    out({"ok": True, "path": str(path), "items": items})


def read_user_dirs() -> dict:
    values = {
        "Desktop": HOME / "Desktop",
        "Documents": HOME / "Documents",
        "Downloads": HOME / "Downloads",
        "Pictures": HOME / "Pictures",
        "Music": HOME / "Music",
        "Videos": HOME / "Videos",
    }
    p = XDG_CONFIG / "user-dirs.dirs"
    if p.exists():
        pattern = re.compile(r'^XDG_(\w+)_DIR="(.*)"$')
        mapping = {
            "DESKTOP": "Desktop",
            "DOCUMENTS": "Documents",
            "DOWNLOAD": "Downloads",
            "PICTURES": "Pictures",
            "MUSIC": "Music",
            "VIDEOS": "Videos",
        }
        for raw in p.read_text(errors="ignore").splitlines():
            m = pattern.match(raw.strip())
            if not m or m.group(1) not in mapping:
                continue
            value = m.group(2).replace("$HOME", str(HOME))
            values[mapping[m.group(1)]] = Path(value)
    return {k: str(v) for k, v in values.items()}


def load_favorites() -> list[dict]:
    try:
        raw = json.loads(FAVORITES_FILE.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return []
    result = []
    seen = set()
    for item in raw if isinstance(raw, list) else []:
        path = Path(str(item.get("path", ""))).expanduser()
        if not path.is_dir():
            continue
        key = str(path.resolve())
        if key in seen:
            continue
        seen.add(key)
        result.append({"label": item.get("label") or path.name or key, "path": key, "icon": "󰉋"})
    return result


def save_favorites(items: list[dict]):
    FAVORITES_FILE.parent.mkdir(parents=True, exist_ok=True)
    FAVORITES_FILE.write_text(json.dumps(items, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def cmd_favorite_add(argv):
    path = Path(argv[0]).expanduser().resolve()
    if not path.is_dir():
        raise ValueError("Only folders can be added to Favorites")
    items = load_favorites()
    if not any(item["path"] == str(path) for item in items):
        items.append({"label": path.name or str(path), "path": str(path), "icon": "󰉋"})
        save_favorites(items)
    out({"ok": True, "favorites": items})


def cmd_favorite_remove(argv):
    path = str(Path(argv[0]).expanduser().resolve())
    items = [item for item in load_favorites() if item["path"] != path]
    save_favorites(items)
    out({"ok": True, "favorites": items})


def physical_devices() -> list[dict]:
    """Return mounted physical disks only; omit swap, loop, zram and pseudo mounts."""
    try:
        proc = subprocess.run(
            ["lsblk", "-J", "-o", "NAME,TYPE,SIZE,MOUNTPOINTS,ROTA,TRAN,MODEL,LABEL,PARTLABEL"],
            text=True, capture_output=True, timeout=3, check=False,
        )
        if proc.returncode != 0:
            return []
        data = json.loads(proc.stdout)
    except Exception:
        return []

    devices = []
    for disk in data.get("blockdevices", []):
        if disk.get("type") != "disk":
            continue
        name = str(disk.get("name", ""))
        if name.startswith(("loop", "zram", "ram", "sr")):
            continue

        candidates = []
        mount_names = {}
        def collect(node):
            node_label = str(node.get("label") or node.get("partlabel") or "").strip()
            for mp in node.get("mountpoints") or []:
                if mp and mp not in ("[SWAP]", "/boot", "/boot/efi"):
                    mp = str(mp)
                    candidates.append(mp)
                    if node_label:
                        mount_names[mp] = node_label
            for child in node.get("children") or []:
                collect(child)
        collect(disk)
        if not candidates:
            continue

        # Prefer a filesystem root, then /home, then normal user/data mountpoints.
        def rank(mp):
            if mp == "/": return 0
            if mp == "/home": return 1
            if mp.startswith("/home/"): return 2
            if mp.startswith(("/mnt/", "/media/", "/run/media/")): return 3
            return 4
        mountpoint = sorted(set(candidates), key=lambda x: (rank(x), len(x)))[0]
        rota = int(disk.get("rota") or 0)
        transport = str(disk.get("tran") or "").lower()
        if transport == "usb":
            continue
        if name.startswith("nvme") or transport == "nvme":
            kind = "NVMe"
            icon = "󰋊"
        elif rota:
            kind = "HDD"
            icon = "󰋊"
        else:
            kind = "SSD"
            icon = "󰋊"
        model_name = str(disk.get("model") or "").strip()
        mount_label = str(mount_names.get(mountpoint) or "").strip()
        home_prefix = str(HOME) + "/"
        if mountpoint.startswith(home_prefix):
            display_name = Path(mountpoint).name
        elif mount_label:
            display_name = mount_label
        elif model_name:
            display_name = model_name
        else:
            display_name = name

        devices.append({
            "label": f"{display_name} · {disk.get('size', '')}",
            "secondary": f"{mountpoint} · {kind}",
            "path": mountpoint,
            "icon": icon,
            "device": name,
            "kind": kind,
        })
    return devices



def external_usb_devices() -> list[dict]:
    """Return physically attached USB disks and their mountable partitions.

    The disk itself becomes one External Device entry while each filesystem-bearing
    child is exposed as a separate partition row. Nothing is returned when no USB
    block device is physically present.
    """
    try:
        proc = subprocess.run(
            ["lsblk", "-J", "-p", "-o",
             "NAME,KNAME,TYPE,SIZE,MOUNTPOINTS,FSTYPE,RO,RM,HOTPLUG,TRAN,MODEL,LABEL,PARTLABEL"],
            text=True, capture_output=True, timeout=3, check=False,
        )
        if proc.returncode != 0:
            return []
        data = json.loads(proc.stdout)
    except Exception:
        return []

    result = []

    def partition_entry(node, fallback_index):
        fstype = str(node.get("fstype") or "").strip()
        node_type = str(node.get("type") or "").strip()
        # Ignore non-filesystem helper nodes. A whole-disk filesystem is valid.
        if node_type not in ("part", "disk"):
            return None
        if not fstype and node_type == "part":
            # Keep a real partition visible even if the fs type cannot be read;
            # udisksctl can still report the actual mount error to the user.
            pass
        mountpoints = [str(x) for x in (node.get("mountpoints") or []) if x and x != "[SWAP]"]
        mountpoint = mountpoints[0] if mountpoints else ""
        label = str(node.get("label") or node.get("partlabel") or "").strip()
        block = str(node.get("name") or "")
        short = Path(block).name
        display = label or (f"Partition {fallback_index}" if node_type == "part" else short)
        return {
            "label": display,
            "secondary": f"{node.get('size','')}" + (f" · {fstype}" if fstype else "") + (f" · {mountpoint}" if mountpoint else " · Not mounted"),
            "block": block,
            "path": mountpoint,
            "mounted": bool(mountpoint),
            "fstype": fstype,
            "size": str(node.get("size") or ""),
        }

    for disk in data.get("blockdevices", []):
        if str(disk.get("type")) != "disk":
            continue
        if str(disk.get("tran") or "").lower() != "usb":
            continue

        disk_block = str(disk.get("name") or "")
        if not disk_block:
            continue
        model = str(disk.get("model") or "").strip()
        label = str(disk.get("label") or "").strip()
        title = model or label or Path(disk_block).name
        partitions = []
        children = disk.get("children") or []
        if children:
            idx = 1
            for child in children:
                ent = partition_entry(child, idx)
                if ent:
                    partitions.append(ent)
                    idx += 1
        else:
            ent = partition_entry(disk, 1)
            if ent:
                partitions.append(ent)

        result.append({
            "label": title,
            "secondary": str(disk.get("size") or ""),
            "block": disk_block,
            "partitions": partitions,
        })
    return result


def _run_udisks(args: list[str]) -> str:
    if shutil.which("udisksctl") is None:
        raise RuntimeError("udisksctl is not installed")
    proc = subprocess.run(["udisksctl", *args], text=True, capture_output=True, timeout=30, check=False)
    message = (proc.stdout or proc.stderr or "").strip()
    if proc.returncode != 0:
        raise RuntimeError(message or "udisksctl command failed")
    return message


def cmd_device_action(argv):
    if len(argv) < 2:
        raise ValueError("device-action requires an action and block device")
    action, block = argv[0], argv[1]
    if not str(block).startswith("/dev/"):
        raise ValueError("Invalid block device")

    if action == "mount":
        msg = _run_udisks(["mount", "-b", block])
    elif action == "unmount":
        msg = _run_udisks(["unmount", "-b", block])
    elif action == "eject":
        # Safe removal: unmount every mounted child first, then power off the
        # physical USB disk so the kernel considers it safe to disconnect.
        try:
            proc = subprocess.run(
                ["lsblk", "-J", "-p", "-o", "NAME,TYPE,MOUNTPOINTS", block],
                text=True, capture_output=True, timeout=3, check=False,
            )
            info = json.loads(proc.stdout) if proc.returncode == 0 else {}
            for disk in info.get("blockdevices", []):
                for child in disk.get("children") or []:
                    if any(x for x in (child.get("mountpoints") or []) if x and x != "[SWAP]"):
                        try:
                            _run_udisks(["unmount", "-b", str(child.get("name"))])
                        except RuntimeError:
                            raise
        except RuntimeError:
            raise
        except Exception:
            pass
        msg = _run_udisks(["power-off", "-b", block])
    else:
        raise ValueError(f"Unknown device action: {action}")

    out({"ok": True, "message": msg})


def cmd_places(_argv):
    dirs = read_user_dirs()
    places = [{"label": "Home", "path": str(HOME), "icon": "󰋜"}]
    icons = {
        "Desktop": "󰍹", "Documents": "󰈙", "Downloads": "󰇚",
        "Pictures": "󰋩", "Music": "󰎄", "Videos": "󰕧"
    }
    for name in ["Desktop", "Documents", "Downloads", "Pictures", "Music", "Videos"]:
        p = Path(dirs[name])
        if p.exists():
            places.append({"label": name, "path": str(p), "icon": icons[name]})
    trash = XDG_DATA / "Trash/files"
    trash.mkdir(parents=True, exist_ok=True)
    places.append({"label": "Trash", "path": str(trash), "icon": "󰩺"})
    out({"places": places, "favorites": load_favorites(), "devices": physical_devices(), "externalDevices": external_usb_devices()})


def unique_target(dest_dir: Path, name: str) -> Path:
    candidate = dest_dir / name
    if not candidate.exists():
        return candidate
    p = Path(name)
    stem, suffix = p.stem, p.suffix
    i = 2
    while True:
        candidate = dest_dir / f"{stem} ({i}){suffix}"
        if not candidate.exists():
            return candidate
        i += 1


def cmd_new_folder(argv):
    parent = Path(argv[0]).expanduser()
    name = argv[1].strip() if len(argv) > 1 else "New Folder"
    if not name or "/" in name:
        raise ValueError("Invalid folder name")
    target = unique_target(parent, name)
    target.mkdir()
    out({"ok": True, "path": str(target)})


def cmd_rename(argv):
    src = Path(argv[0])
    name = argv[1].strip()
    if not name or "/" in name:
        raise ValueError("Invalid name")
    dst = src.with_name(name)
    if dst.exists() and dst != src:
        raise FileExistsError(f"Already exists: {dst.name}")
    src.rename(dst)
    out({"ok": True, "path": str(dst)})


def load_paths(raw: str):
    value = json.loads(raw)
    return [Path(x) for x in value if isinstance(x, str)]


def copy_one(src: Path, dst: Path):
    if src.is_dir() and not src.is_symlink():
        shutil.copytree(src, dst, symlinks=True)
    else:
        shutil.copy2(src, dst, follow_symlinks=False)


def cmd_check_transfer(argv):
    raw, dest_raw = argv[0], argv[1]
    sources = [p for p in load_paths(raw) if p.exists() or p.is_symlink()]
    dest = Path(dest_raw)
    conflicts = []
    for src in sources:
        candidate = dest / src.name
        if candidate.exists() or candidate.is_symlink():
            conflicts.append({"source": str(src), "target": str(candidate), "name": src.name})
    out({"ok": True, "conflicts": conflicts})


def _remove_existing(path: Path):
    if path.is_symlink() or path.is_file():
        path.unlink(missing_ok=True)
    elif path.exists():
        shutil.rmtree(path)


def cmd_transfer(argv):
    mode, raw, dest_raw = argv[0], argv[1], argv[2]
    policy = argv[3] if len(argv) > 3 else "rename"
    if policy not in ("rename", "overwrite", "skip"):
        raise ValueError("Invalid conflict policy")
    sources = [p for p in load_paths(raw) if p.exists() or p.is_symlink()]
    dest = Path(dest_raw)
    dest.mkdir(parents=True, exist_ok=True)
    weights = {str(p): path_weight(p) for p in sources}
    reporter = ProgressReporter("Moving" if mode == "move" else "Copying", sum(weights.values()))
    results = []
    global CURRENT_PARTIAL
    for src in sources:
        preferred = dest / src.name
        if preferred.exists() or preferred.is_symlink():
            if policy == "skip":
                reporter.add(weights[str(src)], src.name)
                continue
            if policy == "overwrite":
                _remove_existing(preferred)
                dst = preferred
            else:
                dst = unique_target(dest, src.name)
        else:
            dst = preferred
        CURRENT_PARTIAL = str(dst)
        weight = weights[str(src)]
        if mode == "move":
            try:
                same_fs = src.lstat().st_dev == dest.stat().st_dev
            except OSError:
                same_fs = False
            if same_fs:
                shutil.move(str(src), str(dst))
                reporter.add(weight, src.name)
            else:
                copy_tree_progress(src, dst, reporter)
                if src.is_dir() and not src.is_symlink():
                    shutil.rmtree(src)
                else:
                    src.unlink(missing_ok=True)
        else:
            copy_tree_progress(src, dst, reporter)
        results.append(str(dst))
        CURRENT_PARTIAL = None
    reporter.finish()
    out({"ok": True, "paths": results})


def cmd_trash(argv):
    sources = [p for p in load_paths(argv[0]) if p.exists() or p.is_symlink()]
    if not shutil.which("gio"):
        raise RuntimeError("gio is required for Move to Trash")
    weights = {str(p): path_weight(p) for p in sources}
    reporter = ProgressReporter("Moving to Trash", sum(weights.values()))
    for source in sources:
        proc = subprocess.run(["gio", "trash", "--", str(source)], capture_output=True, text=True)
        if proc.returncode != 0:
            raise RuntimeError(proc.stderr.strip() or "gio trash failed")
        reporter.add(weights[str(source)], source.name)
    reporter.finish()
    out({"ok": True})



def cmd_empty_trash(argv):
    if not shutil.which("gio"):
        raise RuntimeError("gio is required to empty Trash")
    proc = subprocess.run(["gio", "trash", "--empty"], capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or "Unable to empty Trash")
    out({"ok": True})


def cmd_archive(argv):
    fmt, raw, dest_raw = argv[0], argv[1], argv[2]
    sources = load_paths(raw)
    if not sources:
        raise ValueError("Nothing selected")
    supported = {"zip": "zip", "tar.gz": "gztar", "tar.xz": "xztar"}
    if fmt not in supported:
        raise ValueError("Unsupported archive format")
    dest = Path(dest_raw).expanduser()
    dest.mkdir(parents=True, exist_ok=True)
    if len(sources) == 1:
        base_name = sources[0].stem if sources[0].is_file() else sources[0].name
    else:
        base_name = "Archive"
    suffix = ".zip" if fmt == "zip" else (".tar.gz" if fmt == "tar.gz" else ".tar.xz")
    target = unique_target(dest, base_name + suffix)
    # make_archive wants a basename without the format extension. Build in a temp dir so
    # multiple selections can be archived together without changing their names.
    import tempfile
    with tempfile.TemporaryDirectory(prefix="hypr-files-archive-") as td:
        staging = Path(td) / "content"
        staging.mkdir()
        for src in sources:
            if not src.exists() and not src.is_symlink():
                continue
            dst = staging / src.name
            copy_one(src, dst)
        made = Path(shutil.make_archive(str(Path(td) / "archive"), supported[fmt], root_dir=staging))
        shutil.move(str(made), str(target))
    out({"ok": True, "path": str(target)})


def cmd_extract(argv):
    archive = Path(argv[0]).expanduser()
    dest_parent = Path(argv[1]).expanduser()
    if not archive.is_file():
        raise FileNotFoundError(str(archive))
    name = archive.name
    for suffix in (".tar.gz", ".tar.xz", ".tar.bz2", ".tgz", ".txz", ".tbz2", ".zip", ".tar"):
        if name.lower().endswith(suffix):
            name = name[:-len(suffix)]
            break
    target = unique_target(dest_parent, name)
    target.mkdir(parents=True)
    try:
        shutil.unpack_archive(str(archive), str(target))
    except Exception:
        shutil.rmtree(target, ignore_errors=True)
        raise
    out({"ok": True, "path": str(target)})


def cmd_delete(argv):
    sources = [p for p in load_paths(argv[0]) if p.exists() or p.is_symlink()]
    weights = {str(p): path_weight(p) for p in sources}
    reporter = ProgressReporter("Deleting", sum(weights.values()))
    for p in sources:
        weight = weights[str(p)]
        if p.is_dir() and not p.is_symlink():
            shutil.rmtree(p)
        else:
            p.unlink(missing_ok=True)
        reporter.add(weight, p.name)
    reporter.finish()
    out({"ok": True})


def cmd_open(argv):
    p = argv[0]
    subprocess.Popen(["xdg-open", p], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    out({"ok": True})


def cmd_terminal(argv):
    p = Path(argv[0])
    folder = p if p.is_dir() else p.parent
    terminal = shutil.which("ghostty") or shutil.which("kitty") or shutil.which("foot") or shutil.which("alacritty")
    if not terminal:
        raise RuntimeError("No supported terminal found")
    name = Path(terminal).name
    if name == "ghostty":
        command = [terminal, "--working-directory=" + str(folder)]
    elif name in ("kitty", "alacritty"):
        command = [terminal, "--working-directory", str(folder)]
    else:
        command = [terminal, "-D", str(folder)]
    subprocess.Popen(command, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    out({"ok": True})


def desktop_dirs():
    result = [XDG_DATA / "applications"]
    data_dirs = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share")
    result += [Path(x) / "applications" for x in data_dirs.split(":") if x]
    return result


def parse_desktop(path: Path):
    cp = configparser.ConfigParser(interpolation=None, strict=False)
    try:
        cp.read(path, encoding="utf-8")
        d = cp["Desktop Entry"]
    except Exception:
        return None
    if d.get("Type", "") != "Application" or d.getboolean("NoDisplay", fallback=False):
        return None
    return d


def cmd_apps(argv):
    mime = argv[0]
    apps = []
    seen = set()
    for root in desktop_dirs():
        if not root.exists():
            continue
        for path in root.glob("*.desktop"):
            if path.name in seen:
                continue
            d = parse_desktop(path)
            if not d:
                continue
            mimes = [x for x in d.get("MimeType", "").split(";") if x]
            if mime not in mimes:
                continue
            seen.add(path.name)
            apps.append({
                "id": path.name,
                "name": d.get("Name", path.stem),
                "icon": d.get("Icon", ""),
                "exec": d.get("Exec", "")
            })
    apps.sort(key=lambda x: x["name"].lower())
    out({"apps": apps})


def find_desktop(desktop_id: str):
    for root in desktop_dirs():
        path = root / desktop_id
        if path.exists():
            return path
    return None


def expand_exec(exec_line: str, target: str):
    tokens = shlex.split(exec_line)
    result = []
    used = False
    for token in tokens:
        if token in ("%f", "%F", "%u", "%U"):
            result.append(target)
            used = True
        elif token in ("%i", "%c", "%k"):
            continue
        else:
            token = re.sub(r"%[fFuUick]", "", token)
            if token:
                result.append(token)
    if not used:
        result.append(target)
    return result


def cmd_launch_app(argv):
    desktop_id, target = argv[0], argv[1]
    p = find_desktop(desktop_id)
    if not p:
        raise FileNotFoundError(desktop_id)
    d = parse_desktop(p)
    if not d or not d.get("Exec"):
        raise RuntimeError("Desktop entry has no Exec line")
    command = expand_exec(d.get("Exec"), target)
    subprocess.Popen(command, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    out({"ok": True})


def cmd_info(argv):
    p = Path(argv[0])
    result = info_for(p)
    if p.is_dir():
        try:
            result["itemCount"] = sum(1 for _ in p.iterdir())
        except OSError:
            result["itemCount"] = None
    out(result)


def main():
    if len(sys.argv) < 2:
        raise SystemExit(2)
    command, argv = sys.argv[1], sys.argv[2:]
    commands = {
        "list": cmd_list,
        "places": cmd_places,
        "favorite-add": cmd_favorite_add,
        "favorite-remove": cmd_favorite_remove,
        "device-action": cmd_device_action,
        "new-folder": cmd_new_folder,
        "rename": cmd_rename,
        "check-transfer": cmd_check_transfer,
        "transfer": cmd_transfer,
        "trash": cmd_trash,
        "empty-trash": cmd_empty_trash,
        "archive": cmd_archive,
        "extract": cmd_extract,
        "delete": cmd_delete,
        "open": cmd_open,
        "terminal": cmd_terminal,
        "apps": cmd_apps,
        "launch-app": cmd_launch_app,
        "info": cmd_info,
    }
    try:
        commands[command](argv)
    except KeyError:
        out({"ok": False, "error": f"Unknown command: {command}"})
        raise SystemExit(2)
    except OperationCancelled:
        cleanup_partial()
        out({"ok": False, "cancelled": True, "error": "Operation cancelled"})
        raise SystemExit(130)
    except Exception as exc:
        out({"ok": False, "error": str(exc)})
        raise SystemExit(1)


if __name__ == "__main__":
    main()
