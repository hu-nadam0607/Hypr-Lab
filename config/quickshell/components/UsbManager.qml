import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property bool hasDevices: deviceCount > 0
    property int deviceCount: 0
    property bool initialized: false
    property var knownDevicePaths: []
    property var knownDeviceNames: ({})
    property string lastModelSignature: ""

    property alias rows: rowsModel
    readonly property int rowCount: rowsModel.count

    function refresh() {
        if (!scanProcess.running)
            scanProcess.running = true
    }

    function prepare() {
        refresh()
    }

    function cleanText(value) {
        if (value === null || value === undefined)
            return ""
        return String(value).trim()
    }

    function formatBytes(value) {
        let n = Number(value || 0)
        if (!isFinite(n) || n <= 0)
            return ""
        const units = ["B", "KiB", "MiB", "GiB", "TiB"]
        let i = 0
        while (n >= 1024 && i < units.length - 1) {
            n /= 1024
            ++i
        }
        return n.toFixed(i >= 3 ? 1 : 0) + " " + units[i]
    }

    function deviceTitle(node) {
        const vendor = cleanText(node.vendor)
        const model = cleanText(node.model)
        const name = (vendor + " " + model).trim()
        return name !== "" ? name : cleanText(node.path)
    }

    function firstMountPoint(node) {
        if (node.mountpoints) {
            for (let i = 0; i < node.mountpoints.length; ++i) {
                const p = cleanText(node.mountpoints[i])
                if (p !== "")
                    return p
            }
        }
        return cleanText(node.mountpoint)
    }

    function collectPartitions(node, diskPath, output) {
        const children = node && node.children ? node.children : []
        for (let i = 0; i < children.length; ++i) {
            const child = children[i]
            const type = cleanText(child.type)
            if (type === "part") {
                const path = cleanText(child.path)
                const label = cleanText(child.label)
                const fs = cleanText(child.fstype)
                const mp = firstMountPoint(child)
                output.push({
                    rowType: "partition",
                    path: path,
                    parentPath: diskPath,
                    title: label !== "" ? label : path,
                    subtitle: [fs, formatBytes(child.size)].filter(function(v) { return v !== "" }).join(" · "),
                    fstype: fs,
                    mountPoint: mp,
                    mounted: mp !== ""
                })
            }

            // Keep walking: lsblk can nest partitions below intermediate nodes.
            collectPartitions(child, diskPath, output)
        }
    }

    function anyMountedPartition(parts) {
        for (let i = 0; i < parts.length; ++i) {
            if (parts[i].mounted)
                return true
        }
        return false
    }

    function announce(title, body, urgency) {
        const args = ["notify-send", "-a", "Hypr-Lab"]
        if (urgency)
            args.push("-u", urgency)
        args.push(title, body)
        Quickshell.execDetached(args)
    }

    function applyScan(raw) {
        let parsed
        try {
            parsed = JSON.parse(raw)
        } catch (error) {
            console.warn("USB Manager: lsblk JSON parse failed:", error)
            return
        }

        const blocks = parsed && parsed.blockdevices ? parsed.blockdevices : []
        const devices = []

        for (let i = 0; i < blocks.length; ++i) {
            const disk = blocks[i]
            if (cleanText(disk.type) !== "disk")
                continue

            const tran = cleanText(disk.tran).toLowerCase()
            const removable = Number(disk.rm || 0) === 1
            const hotplug = Number(disk.hotplug || 0) === 1

            if (tran !== "usb" && !removable && !hotplug)
                continue

            devices.push(disk)
        }

        const newPaths = []
        const newNames = ({})
        const nextRows = []

        for (let d = 0; d < devices.length; ++d) {
            const disk = devices[d]
            const diskPath = cleanText(disk.path)
            const title = deviceTitle(disk)
            const parts = []

            collectPartitions(disk, diskPath, parts)

            // Filesystem directly on the physical USB device (no partition table).
            if (parts.length === 0 && cleanText(disk.fstype) !== "") {
                const mp = firstMountPoint(disk)
                parts.push({
                    rowType: "partition",
                    path: diskPath,
                    parentPath: diskPath,
                    title: cleanText(disk.label) !== ""
                        ? cleanText(disk.label)
                        : diskPath,
                    subtitle: [
                        cleanText(disk.fstype),
                        formatBytes(disk.size)
                    ].filter(function(v) { return v !== "" }).join(" · "),
                    fstype: cleanText(disk.fstype),
                    mountPoint: mp,
                    mounted: mp !== ""
                })
            }

            newPaths.push(diskPath)
            newNames[diskPath] = title

            nextRows.push({
                rowType: "device",
                path: diskPath,
                parentPath: "",
                title: title,
                subtitle: [
                    formatBytes(disk.size),
                    parts.length + (parts.length === 1 ? " volume" : " volumes")
                ].join(" · "),
                fstype: "",
                mountPoint: "",
                mounted: anyMountedPartition(parts)
            })

            for (let p = 0; p < parts.length; ++p)
                nextRows.push(parts[p])
        }

        // Build a deterministic semantic signature. If lsblk reports exactly
        // the same visible state, keep the existing ListModel and delegates.
        // This is what prevents the panel from pulsing every scan interval.
        const nextSignature = JSON.stringify(nextRows)

        deviceCount = devices.length

        if (initialized) {
            for (let i = 0; i < newPaths.length; ++i) {
                const path = newPaths[i]
                if (knownDevicePaths.indexOf(path) === -1)
                    announce(
                        "USB eszköz csatlakoztatva",
                        newNames[path] || path
                    )
            }

            for (let i = 0; i < knownDevicePaths.length; ++i) {
                const path = knownDevicePaths[i]
                if (newPaths.indexOf(path) === -1)
                    announce(
                        "USB eszköz eltávolítva",
                        knownDeviceNames[path] || path
                    )
            }
        }

        knownDevicePaths = newPaths
        knownDeviceNames = newNames
        initialized = true

        if (nextSignature === lastModelSignature)
            return

        lastModelSignature = nextSignature

        rowsModel.clear()
        for (let i = 0; i < nextRows.length; ++i)
            rowsModel.append(nextRows[i])
    }

    function mount(path) {
        Quickshell.execDetached([
            "bash", "-c",
            'if out=$(udisksctl mount -b "$1" 2>&1); then ' +
            'notify-send -a Hypr-Lab "USB partíció csatlakoztatva" "$out"; ' +
            'else notify-send -a Hypr-Lab -u critical "USB csatlakoztatási hiba" "$out"; fi',
            "bash", path
        ])
        actionRefresh.restart()
    }

    function unmount(path) {
        Quickshell.execDetached([
            "bash", "-c",
            'if out=$(udisksctl unmount -b "$1" 2>&1); then ' +
            'notify-send -a Hypr-Lab "USB partíció leválasztva" "$out"; ' +
            'else notify-send -a Hypr-Lab -u critical "USB leválasztási hiba" "$out"; fi',
            "bash", path
        ])
        actionRefresh.restart()
    }

    // Device-level "mount" means: mount every mountable filesystem belonging
    // to this physical USB disk. A partitioned disk itself is not a filesystem.
    function mountDevice(path) {
        Quickshell.execDetached([
            "bash", "-c",
            'dev="$1"; ok=1; msg=""; ' +
            'while read -r p t fs; do ' +
            '  [ -n "$fs" ] || continue; ' +
            '  [ "$p" = "$dev" ] || [ "$t" = "part" ] || continue; ' +
            '  if ! findmnt -rn -S "$p" >/dev/null 2>&1; then ' +
            '    out=$(udisksctl mount -b "$p" 2>&1) || ok=0; ' +
            '    msg="${msg}${out}\n"; ' +
            '  fi; ' +
            'done < <(lsblk -nrpo PATH,TYPE,FSTYPE "$dev"); ' +
            'if [ "$ok" -eq 1 ]; then ' +
            '  notify-send -a Hypr-Lab "USB eszköz csatlakoztatva" "Minden elérhető fájlrendszer csatlakoztatva."; ' +
            'else notify-send -a Hypr-Lab -u critical "USB csatlakoztatási hiba" "$msg"; fi',
            "bash", path
        ])
        actionRefresh.restart()
    }

    // Device-level "unmount" means: unmount every mounted filesystem below
    // the disk, but keep the physical USB device powered.
    function unmountDevice(path) {
        Quickshell.execDetached([
            "bash", "-c",
            'dev="$1"; ok=1; msg=""; ' +
            'mapfile -t nodes < <(lsblk -nrpo PATH "$dev" | tac); ' +
            'for p in "${nodes[@]}"; do ' +
            '  [ "$p" = "$dev" ] && continue; ' +
            '  if findmnt -rn -S "$p" >/dev/null 2>&1; then ' +
            '    out=$(udisksctl unmount -b "$p" 2>&1) || ok=0; ' +
            '    msg="${msg}${out}\n"; ' +
            '  fi; ' +
            'done; ' +
            'if findmnt -rn -S "$dev" >/dev/null 2>&1; then ' +
            '  out=$(udisksctl unmount -b "$dev" 2>&1) || ok=0; msg="${msg}${out}\n"; ' +
            'fi; ' +
            'if [ "$ok" -eq 1 ]; then ' +
            '  notify-send -a Hypr-Lab "USB eszköz leválasztva" "Minden csatolt fájlrendszer unmountolva."; ' +
            'else notify-send -a Hypr-Lab -u critical "USB leválasztási hiba" "$msg"; fi',
            "bash", path
        ])
        actionRefresh.restart()
    }

    // Safe removal: unmount every mounted descendant first, then power the
    // physical drive off through UDisks. This is the actual "safe eject".
    function safelyRemove(path) {
        Quickshell.execDetached([
            "bash", "-c",
            'dev="$1"; ok=1; msg=""; ' +
            'mapfile -t nodes < <(lsblk -nrpo PATH "$dev" | tac); ' +
            'for p in "${nodes[@]}"; do ' +
            '  if findmnt -rn -S "$p" >/dev/null 2>&1; then ' +
            '    out=$(udisksctl unmount -b "$p" 2>&1) || ok=0; ' +
            '    msg="${msg}${out}\n"; ' +
            '  fi; ' +
            'done; ' +
            'if [ "$ok" -eq 1 ]; then ' +
            '  if out=$(udisksctl power-off -b "$dev" 2>&1); then ' +
            '    notify-send -a Hypr-Lab "USB biztonságosan eltávolítva" "$dev"; exit 0; ' +
            '  else msg="${msg}${out}\n"; fi; ' +
            'fi; ' +
            'notify-send -a Hypr-Lab -u critical "USB eltávolítási hiba" "${msg:-Az eszköz nem választható le biztonságosan.}"; exit 1',
            "bash", path
        ])
        actionRefresh.restart()
    }

    ListModel { id: rowsModel }

    Process {
        id: scanProcess
        command: [
            "lsblk", "-J", "-b",
            "-o", "NAME,PATH,TYPE,TRAN,RM,HOTPLUG,LABEL,FSTYPE,SIZE,MOUNTPOINT,MOUNTPOINTS,MODEL,VENDOR"
        ]
        stdout: StdioCollector {
            onStreamFinished: root.applyScan(text)
        }
    }

    Timer {
        interval: 3500
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        id: actionRefresh
        interval: 850
        repeat: false
        onTriggered: root.refresh()
    }
}
