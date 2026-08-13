import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    property var anchorItem: null
    property bool hasDevices: deviceCount > 0
    property int deviceCount: 0
    property bool initialized: false
    property var knownDevicePaths: []
    property var knownDeviceNames: ({})

    function refresh() {
        if (!scanProcess.running)
            scanProcess.running = true
    }

    function toggle(item) {
        if (item)
            root.anchorItem = item

        if (!root.hasDevices) {
            popup.visible = false
            return
        }

        popup.visible = !popup.visible
        if (popup.visible)
            root.refresh()
    }

    function close() {
        popup.visible = false
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
        const digits = i >= 3 ? 1 : 0
        return n.toFixed(digits) + " " + units[i]
    }

    function cleanText(value) {
        if (value === null || value === undefined)
            return ""
        return String(value).trim()
    }

    function deviceTitle(node) {
        const vendor = root.cleanText(node.vendor)
        const model = root.cleanText(node.model)
        const joined = (vendor + " " + model).trim()
        return joined !== "" ? joined : root.cleanText(node.path)
    }

    function firstMountPoint(node) {
        if (!node.mountpoints)
            return ""

        for (let i = 0; i < node.mountpoints.length; ++i) {
            const point = node.mountpoints[i]
            if (point !== null && String(point).trim() !== "")
                return String(point)
        }
        return ""
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

        const devices = []
        const blocks = parsed && parsed.blockdevices ? parsed.blockdevices : []

        for (let i = 0; i < blocks.length; ++i) {
            const disk = blocks[i]
            if (root.cleanText(disk.type) !== "disk")
                continue

            // TRAN=usb is the reliable signal for USB mass-storage devices.
            if (root.cleanText(disk.tran).toLowerCase() !== "usb")
                continue

            devices.push(disk)
        }

        const newPaths = []
        const newNames = ({})

        rowsModel.clear()

        for (let d = 0; d < devices.length; ++d) {
            const disk = devices[d]
            const diskPath = root.cleanText(disk.path)
            const title = root.deviceTitle(disk)
            newPaths.push(diskPath)
            newNames[diskPath] = title

            rowsModel.append({
                rowType: "device",
                path: diskPath,
                parentPath: "",
                title: title,
                subtitle: root.formatBytes(disk.size),
                fstype: "",
                mountPoint: "",
                mounted: false
            })

            const children = disk.children || []
            let partitionCount = 0
            for (let p = 0; p < children.length; ++p) {
                const part = children[p]
                if (root.cleanText(part.type) !== "part")
                    continue

                ++partitionCount
                const partPath = root.cleanText(part.path)
                const label = root.cleanText(part.label)
                const fs = root.cleanText(part.fstype)
                const mountPoint = root.firstMountPoint(part)
                const size = root.formatBytes(part.size)

                rowsModel.append({
                    rowType: "partition",
                    path: partPath,
                    parentPath: diskPath,
                    title: label !== "" ? label : partPath,
                    subtitle: [fs, size].filter(function(x) { return x !== "" }).join(" · "),
                    fstype: fs,
                    mountPoint: mountPoint,
                    mounted: mountPoint !== ""
                })
            }

            if (partitionCount === 0) {
                // Some removable media expose the filesystem directly on the disk.
                const fs = root.cleanText(disk.fstype)
                if (fs !== "") {
                    const mountPoint = root.firstMountPoint(disk)
                    rowsModel.append({
                        rowType: "partition",
                        path: diskPath,
                        parentPath: diskPath,
                        title: root.cleanText(disk.label) !== "" ? root.cleanText(disk.label) : diskPath,
                        subtitle: [fs, root.formatBytes(disk.size)].filter(function(x) { return x !== "" }).join(" · "),
                        fstype: fs,
                        mountPoint: mountPoint,
                        mounted: mountPoint !== ""
                    })
                }
            }
        }

        root.deviceCount = devices.length

        if (root.initialized) {
            for (let i = 0; i < newPaths.length; ++i) {
                const path = newPaths[i]
                if (root.knownDevicePaths.indexOf(path) === -1)
                    root.announce("USB eszköz csatlakoztatva", newNames[path] || path)
            }

            for (let i = 0; i < root.knownDevicePaths.length; ++i) {
                const path = root.knownDevicePaths[i]
                if (newPaths.indexOf(path) === -1)
                    root.announce("USB eszköz eltávolítva", root.knownDeviceNames[path] || path)
            }
        }

        root.knownDevicePaths = newPaths
        root.knownDeviceNames = newNames
        root.initialized = true

        if (root.deviceCount === 0)
            popup.visible = false
    }

    function mount(path) {
        Quickshell.execDetached([
            "sh", "-c",
            'if out=$(udisksctl mount -b "$1" 2>&1); then ' +
            'notify-send -a Hypr-Lab "USB partíció csatlakoztatva" "$out"; ' +
            'else notify-send -a Hypr-Lab -u critical "USB csatlakoztatási hiba" "$out"; fi',
            "sh", path
        ])
        actionRefresh.restart()
    }

    function unmount(path) {
        Quickshell.execDetached([
            "sh", "-c",
            'if out=$(udisksctl unmount -b "$1" 2>&1); then ' +
            'notify-send -a Hypr-Lab "USB partíció leválasztva" "$out"; ' +
            'else notify-send -a Hypr-Lab -u critical "USB leválasztási hiba" "$out"; fi',
            "sh", path
        ])
        actionRefresh.restart()
    }

    function safelyRemove(path) {
        popup.visible = false
        Quickshell.execDetached([
            "bash", "-c",
            'dev="$1"; ok=1; ' +
            'while read -r p t; do ' +
            '  if [ "$t" = "part" ] && findmnt -rn -S "$p" >/dev/null 2>&1; then ' +
            '    udisksctl unmount -b "$p" >/dev/null 2>&1 || ok=0; ' +
            '  fi; ' +
            'done < <(lsblk -nrpo PATH,TYPE "$dev"); ' +
            'if [ "$ok" -eq 1 ] && out=$(udisksctl power-off -b "$dev" 2>&1); then ' +
            '  exit 0; ' +
            'else ' +
            '  notify-send -a Hypr-Lab -u critical "USB eltávolítási hiba" "${out:-Az eszköz nem választható le biztonságosan.}"; ' +
            '  exit 1; ' +
            'fi',
            "bash", path
        ])
        actionRefresh.restart()
    }

    ListModel {
        id: rowsModel
    }

    Process {
        id: scanProcess
        command: [
            "lsblk", "-J", "-b",
            "-o", "NAME,PATH,TYPE,TRAN,RM,HOTPLUG,LABEL,FSTYPE,SIZE,MOUNTPOINTS,MODEL,VENDOR"
        ]

        stdout: StdioCollector {
            onStreamFinished: root.applyScan(text)
        }
    }

    Timer {
        interval: 1400
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        id: actionRefresh
        interval: 1100
        repeat: false
        onTriggered: root.refresh()
    }

    PopupWindow {
        id: popup

        implicitWidth: 410
        implicitHeight: Math.min(430, 70 + rowsList.contentHeight)
        color: "transparent"
        visible: false
        grabFocus: true

        anchor.item: root.anchorItem
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Right
        anchor.margins.bottom: -8
        anchor.adjustment: PopupAdjustment.Flip | PopupAdjustment.Slide

        onVisibleChanged: {
            if (visible) {
                panel.opacity = 0
                panel.scale = 0.96
                openAnimation.restart()
            }
        }

        ParallelAnimation {
            id: openAnimation
            NumberAnimation {
                target: panel
                property: "opacity"
                from: 0
                to: 1
                duration: 150
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: panel
                property: "scale"
                from: 0.96
                to: 1
                duration: 190
                easing.type: Easing.OutBack
            }
        }

        BackgroundEffect.blurRegion: Region { item: panel }

        Shadow {
            sourceItem: panel
            z: -2
        }

        Glow {
            sourceItem: panel
            z: -1
        }

        Rectangle {
            id: panel
            anchors.fill: parent
            radius: 18
            color: Qt.rgba(10 / 255, 12 / 255, 18 / 255, 0.78)
            border.width: 2
            border.color: Qt.rgba(55 / 255, 245 / 255, 235 / 255, 0.62)
            transformOrigin: Item.TopRight

            Text {
                id: title
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.top: parent.top
                anchors.topMargin: 13
                text: "USB DEVICES"
                color: Qt.rgba(1, 1, 1, 0.92)
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                font.bold: true
            }

            Text {
                anchors.left: title.left
                anchors.top: title.bottom
                anchors.topMargin: 2
                text: root.deviceCount === 1 ? "1 removable device" : root.deviceCount + " removable devices"
                color: Qt.rgba(1, 1, 1, 0.40)
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 9
            }

            Rectangle {
                width: 28
                height: 28
                radius: 8
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.top: parent.top
                anchors.topMargin: 10
                color: closeMouse.containsMouse ? Qt.rgba(55 / 255, 245 / 255, 235 / 255, 0.12) : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: Qt.rgba(1, 1, 1, 0.70)
                    font.pixelSize: 18
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 58
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                height: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            ListView {
                id: rowsList
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 66
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                clip: true
                spacing: 5
                model: rowsModel
                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                    id: row
                    required property string rowType
                    required property string path
                    required property string parentPath
                    required property string title
                    required property string subtitle
                    required property string fstype
                    required property string mountPoint
                    required property bool mounted

                    width: rowsList.width
                    height: rowType === "device" ? 60 : 68

                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: row.rowType === "partition" ? 14 : 0
                        radius: 12
                        color: rowMouse.containsMouse
                               ? Qt.rgba(55 / 255, 245 / 255, 235 / 255, 0.08)
                               : Qt.rgba(1, 1, 1, row.rowType === "device" ? 0.035 : 0.022)
                        border.width: 1
                        border.color: row.rowType === "device"
                                      ? Qt.rgba(55 / 255, 245 / 255, 235 / 255, 0.16)
                                      : Qt.rgba(1, 1, 1, 0.06)

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            id: rowIcon
                            anchors.left: parent.left
                            anchors.leftMargin: 11
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.rowType === "device" ? "󰕓" : (row.mounted ? "󰉉" : "󰋊")
                            color: row.rowType === "device"
                                   ? Qt.rgba(55 / 255, 245 / 255, 235 / 255, 0.92)
                                   : Qt.rgba(1, 1, 1, 0.62)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 17
                        }

                        Text {
                            id: rowTitle
                            anchors.left: rowIcon.right
                            anchors.leftMargin: 10
                            anchors.right: actionButton.left
                            anchors.rightMargin: 8
                            anchors.top: parent.top
                            anchors.topMargin: row.rowType === "device" ? 10 : 8
                            text: row.title
                            elide: Text.ElideRight
                            color: Qt.rgba(1, 1, 1, 0.88)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            font.bold: row.rowType === "device"
                        }

                        Text {
                            id: rowSub
                            anchors.left: rowTitle.left
                            anchors.right: actionButton.left
                            anchors.rightMargin: 8
                            anchors.top: rowTitle.bottom
                            anchors.topMargin: 2
                            text: row.subtitle
                            elide: Text.ElideRight
                            color: Qt.rgba(1, 1, 1, 0.42)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 8
                        }

                        Text {
                            visible: row.rowType === "partition"
                            anchors.left: rowTitle.left
                            anchors.right: actionButton.left
                            anchors.rightMargin: 8
                            anchors.top: rowSub.bottom
                            anchors.topMargin: 2
                            text: row.mounted ? row.mountPoint : "Not mounted"
                            elide: Text.ElideMiddle
                            color: row.mounted
                                   ? Qt.rgba(55 / 255, 245 / 255, 235 / 255, 0.62)
                                   : Qt.rgba(1, 1, 1, 0.28)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 8
                        }

                        Rectangle {
                            id: actionButton
                            width: row.rowType === "device" ? 96 : 82
                            height: 30
                            radius: 10
                            anchors.right: parent.right
                            anchors.rightMargin: 9
                            anchors.verticalCenter: parent.verticalCenter
                            color: actionMouse.containsMouse
                                   ? Qt.rgba(55 / 255, 245 / 255, 235 / 255, 0.17)
                                   : Qt.rgba(55 / 255, 245 / 255, 235 / 255, 0.07)
                            border.width: 1
                            border.color: Qt.rgba(55 / 255, 245 / 255, 235 / 255, 0.24)

                            Text {
                                anchors.centerIn: parent
                                text: row.rowType === "device"
                                      ? "EJECT"
                                      : (row.mounted ? "UNMOUNT" : "MOUNT")
                                color: Qt.rgba(55 / 255, 245 / 255, 235 / 255, 0.92)
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 9
                                font.bold: true
                            }

                            MouseArea {
                                id: actionMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (row.rowType === "device")
                                        root.safelyRemove(row.path)
                                    else if (row.mounted)
                                        root.unmount(row.path)
                                    else
                                        root.mount(row.path)
                                }
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            anchors.rightMargin: actionButton.width + 16
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }
                    }
                }
            }
        }
    }
}
