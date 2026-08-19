import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: root

    signal backRequested()
    signal closeRequested()

    property color accentColor: "#68787D"
    property real slope: 14 / 36
    property real corridorWidth: 360
    property real corridorTopLeft: 0

    property var monitors: []
    property int selectedIndex: 0
    readonly property var current:
        monitors.length > 0
        ? monitors[Math.min(selectedIndex, monitors.length - 1)]
        : null

    property int modeIndex: 0
    property real selectedScale: current && current.scale !== undefined
        ? Number(current.scale)
        : 1.0

    function rowX(viewY) {
        return corridorTopLeft - slope * Math.max(0, viewY)
    }

    function script() {
        return Quickshell.env("HOME")
            + "/.config/hypr/hyprlab-scripts/hyprlab-settings.sh"
    }

    function refresh() {
        if (!monitorProc.running)
            monitorProc.running = true
    }

    function currentModeString(mon) {
        if (!mon)
            return ""

        const w = Number(mon.width || 0)
        const h = Number(mon.height || 0)
        const r = Number(mon.refreshRate || 0)
        return w + "x" + h + "@" + r.toFixed(2)
    }

    function findModeIndex() {
        if (!current || !current.availableModes)
            return 0

        const wantedRes = Number(current.width || 0) + "x" + Number(current.height || 0)
        let nearest = 0
        let nearestDelta = 999999
        const currentRefresh = Number(current.refreshRate || 0)

        for (let i = 0; i < current.availableModes.length; ++i) {
            const mode = String(current.availableModes[i])
            if (mode.indexOf(wantedRes + "@") !== 0)
                continue

            const refreshText = mode.substring(mode.indexOf("@") + 1).replace(/Hz$/, "")
            const refresh = Number(refreshText)
            const delta = Math.abs(refresh - currentRefresh)

            if (delta < nearestDelta) {
                nearest = i
                nearestDelta = delta
            }
        }

        return nearest
    }

    function selectMonitor(index) {
        if (monitors.length === 0)
            return

        selectedIndex = Math.max(0, Math.min(index, monitors.length - 1))
        modeIndex = findModeIndex()
        selectedScale = current && current.scale !== undefined
            ? Number(current.scale)
            : 1.0
    }

    function applyMode() {
        if (!current || !current.availableModes || current.availableModes.length === 0)
            return

        const mode = String(current.availableModes[modeIndex])
        const position = String(Number(current.x || 0)) + "x" + String(Number(current.y || 0))

        Quickshell.execDetached([
            "bash",
            script(),
            "monitor-mode",
            String(current.name),
            mode,
            String(selectedScale),
            position
        ])

        refreshDelay.restart()
    }

    function applyScale() {
        if (!current)
            return

        Quickshell.execDetached([
            "bash",
            script(),
            "monitor-scale",
            String(current.name),
            String(selectedScale)
        ])

        refreshDelay.restart()
    }

    Process {
        id: monitorProc
        command: ["bash", root.script(), "monitors"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text)
                    root.monitors = Array.isArray(parsed) ? parsed : []

                    if (root.selectedIndex >= root.monitors.length)
                        root.selectedIndex = 0

                    root.modeIndex = root.findModeIndex()

                    if (root.current && root.current.scale !== undefined)
                        root.selectedScale = Number(root.current.scale)
                } catch (error) {
                    console.warn("Hypr-Lab Monitor Settings: failed to parse monitor JSON:", error)
                    root.monitors = []
                    root.selectedIndex = 0
                    root.modeIndex = 0
                }
            }
        }
    }

    Timer {
        id: refreshDelay
        interval: 500
        repeat: false
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight + 18
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 1900

        Column {
            id: content
            width: flick.width
            spacing: 0

            Item {
                x: root.rowX(y - flick.contentY)
                width: root.corridorWidth
                height: 42

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "‹ Vissza"
                    color: backMouse.containsMouse ? root.accentColor : Qt.rgba(1,1,1,0.68)
                    font.family: "Inter"
                    font.pixelSize: 10
                    font.bold: true
                    font.italic: true

                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        anchors.margins: -7
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.backRequested()
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "MONITOR & DISPLAY"
                        color: "white"
                        font.family: "Inter"
                        font.pixelSize: 11
                        font.bold: true
                        font.italic: true
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Hyprland detected outputs"
                        color: Qt.rgba(1,1,1,0.38)
                        font.family: "Inter"
                        font.pixelSize: 8
                        font.italic: true
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "×"
                    color: closeMouse.containsMouse ? root.accentColor : Qt.rgba(1,1,1,0.60)
                    font.family: "Inter"
                    font.pixelSize: 17
                    font.bold: true

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }
            }

            Text {
                x: root.rowX(y - flick.contentY)
                width: root.corridorWidth
                height: 24
                text: "CONNECTED DISPLAY"
                color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.78)
                font.family: "Inter"
                font.pixelSize: 8
                font.bold: true
                font.italic: true
                font.letterSpacing: 1.3
                verticalAlignment: Text.AlignVCenter
            }

            Item {
                x: root.rowX(y - flick.contentY)
                width: root.corridorWidth
                height: 68

                Column {
                    anchors.left: parent.left
                    anchors.right: nextMonitor.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        text: root.current ? String(root.current.name || "Unknown output") : "No display detected"
                        color: root.accentColor
                        font.family: "Inter"
                        font.pixelSize: 11
                        font.bold: true
                        font.italic: true
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: root.current
                            ? String(root.current.description || (String(root.current.make || "") + " " + String(root.current.model || "")))
                            : "Hyprland did not report an output"
                        color: Qt.rgba(1,1,1,0.46)
                        font.family: "Inter"
                        font.pixelSize: 8
                        font.italic: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: root.current
                            ? root.currentModeString(root.current) + " · scale " + Number(root.current.scale || 1).toFixed(2)
                            : ""
                        color: Qt.rgba(1,1,1,0.66)
                        font.family: "Inter"
                        font.pixelSize: 8
                        font.italic: true
                    }
                }

                Text {
                    id: nextMonitor
                    visible: root.monitors.length > 1
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: (root.selectedIndex + 1) + "/" + root.monitors.length + "  ›"
                    color: nextMonitorMouse.containsMouse ? root.accentColor : Qt.rgba(1,1,1,0.56)
                    font.family: "Inter"
                    font.pixelSize: 9
                    font.bold: true
                    font.italic: true

                    MouseArea {
                        id: nextMonitorMouse
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            modeSelector.expanded = false
                            root.selectMonitor((root.selectedIndex + 1) % root.monitors.length)
                        }
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.18)
                }
            }

            Text {
                x: root.rowX(y - flick.contentY)
                width: root.corridorWidth
                height: 28
                text: "RESOLUTION & REFRESH"
                color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.78)
                font.family: "Inter"
                font.pixelSize: 8
                font.bold: true
                font.italic: true
                font.letterSpacing: 1.3
                verticalAlignment: Text.AlignVCenter
            }

            Item {
                id: modeSelector
                property bool expanded: false

                x: root.rowX(y - flick.contentY)
                width: root.corridorWidth
                height: 50

                Column {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        text: "Display mode"
                        color: Qt.rgba(1,1,1,0.82)
                        font.family: "Inter"
                        font.pixelSize: 10
                        font.bold: true
                        font.italic: true
                    }

                    Text {
                        text: "Resolution and refresh rate"
                        color: Qt.rgba(1,1,1,0.38)
                        font.family: "Inter"
                        font.pixelSize: 8
                        font.italic: true
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.current && root.current.availableModes && root.current.availableModes.length > 0
                        ? String(root.current.availableModes[root.modeIndex]) + (modeSelector.expanded ? "  ⌃" : "  ⌄")
                        : "—"
                    color: root.accentColor
                    font.family: "Inter"
                    font.pixelSize: 9
                    font.bold: true
                    font.italic: true
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: modeMouse.containsMouse
                        ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.62)
                        : Qt.rgba(1,1,1,0.09)
                }

                MouseArea {
                    id: modeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.current && root.current.availableModes && root.current.availableModes.length > 0)
                            modeSelector.expanded = !modeSelector.expanded
                    }
                }
            }

            Item {
                id: modeDropdown
                visible: modeSelector.expanded

                // The dropdown is an envelope around the same slanted corridor
                // as the parent Monitor & Display page.  Every visible mode row
                // computes its own X position from its current viewport Y, so
                // scrolling preserves the /______/ geometry instead of turning
                // into a rectangular popup.
                readonly property real visibleHeight:
                    visible ? Math.min(188, 8 + modeList.contentHeight) : 0

                x: root.rowX(y - flick.contentY) - root.slope * visibleHeight
                width: root.corridorWidth + root.slope * visibleHeight
                height: visibleHeight
                clip: true

                Behavior on height {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }

                ListView {
                    id: modeList
                    anchors.fill: parent
                    clip: true
                    spacing: 0
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 1900
                    model: root.current && root.current.availableModes
                        ? root.current.availableModes
                        : []

                    delegate: Item {
                        id: modeDelegate
                        required property string modelData
                        required property int index

                        width: modeList.width
                        height: 34

                        // Use the row's top edge as the geometry reference.
                        // This keeps the first visible entry exactly on the
                        // parent panel's left border instead of starting a few
                        // pixels outside it, while lower rows still follow the
                        // same slanted corridor during scrolling.
                        readonly property real viewportY:
                            y - modeList.contentY

                        Item {
                            id: slantedModeRow
                            // Anchor rows to the dropdown's *target* slanted envelope,
                            // not its currently animated height.  Using modeDropdown.height
                            // made the whole list travel in from left of the panel border
                            // while the dropdown height was springing/opening.
                            x: root.slope * modeDropdown.visibleHeight
                                - root.slope * modeDelegate.viewportY
                            width: root.corridorWidth
                            height: parent.height

                            Rectangle {
                                anchors.fill: parent
                                color: modeRowMouse.containsMouse
                                    ? Qt.rgba(
                                        root.accentColor.r,
                                        root.accentColor.g,
                                        root.accentColor.b,
                                        0.055
                                    )
                                    : "transparent"
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 2
                                anchors.right: selectedMark.left
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: modeDelegate.modelData
                                color: modeDelegate.index === root.modeIndex
                                    ? root.accentColor
                                    : Qt.rgba(1,1,1,0.68)
                                font.family: "Inter"
                                font.pixelSize: 9
                                font.bold: modeDelegate.index === root.modeIndex
                                font.italic: true
                                elide: Text.ElideRight
                            }

                            Text {
                                id: selectedMark
                                visible: modeDelegate.index === root.modeIndex
                                anchors.right: parent.right
                                anchors.rightMargin: 2
                                anchors.verticalCenter: parent.verticalCenter
                                text: "✓"
                                color: root.accentColor
                                font.family: "Inter"
                                font.pixelSize: 10
                                font.bold: true
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 1
                                color: modeDelegate.index === root.modeIndex
                                    ? Qt.rgba(
                                        root.accentColor.r,
                                        root.accentColor.g,
                                        root.accentColor.b,
                                        0.34
                                    )
                                    : Qt.rgba(1,1,1,0.06)
                            }

                            MouseArea {
                                id: modeRowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.modeIndex = modeDelegate.index
                                    modeSelector.expanded = false
                                    root.applyMode()
                                }
                            }
                        }
                    }
                }

                // Subtle upper/lower guide lines follow the dropdown envelope.
                Rectangle {
                    x: root.slope * modeDropdown.height
                    y: 0
                    width: root.corridorWidth
                    height: 1
                    color: Qt.rgba(
                        root.accentColor.r,
                        root.accentColor.g,
                        root.accentColor.b,
                        0.16
                    )
                    z: 4
                }

                Rectangle {
                    x: 0
                    y: modeDropdown.height - 1
                    width: root.corridorWidth
                    height: 1
                    color: Qt.rgba(
                        root.accentColor.r,
                        root.accentColor.g,
                        root.accentColor.b,
                        0.16
                    )
                    z: 4
                }
            }

            Item {
                x: root.rowX(y - flick.contentY)
                width: root.corridorWidth
                height: 52

                Column {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        text: "Scale"
                        color: Qt.rgba(1,1,1,0.82)
                        font.family: "Inter"
                        font.pixelSize: 10
                        font.bold: true
                        font.italic: true
                    }

                    Text {
                        text: "Logical display scaling"
                        color: Qt.rgba(1,1,1,0.38)
                        font.family: "Inter"
                        font.pixelSize: 8
                        font.italic: true
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 11

                    Text {
                        text: "−"
                        color: scaleDown.containsMouse ? root.accentColor : Qt.rgba(1,1,1,0.62)
                        font.family: "Inter"
                        font.pixelSize: 13
                        font.bold: true
                        MouseArea {
                            id: scaleDown
                            anchors.fill: parent
                            anchors.margins: -7
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedScale = Math.max(0.5, Math.round((root.selectedScale - 0.05) * 100) / 100)
                                root.applyScale()
                            }
                        }
                    }

                    Text {
                        text: root.selectedScale.toFixed(2) + "×"
                        color: root.accentColor
                        font.family: "Inter"
                        font.pixelSize: 9
                        font.bold: true
                        font.italic: true
                    }

                    Text {
                        text: "+"
                        color: scaleUp.containsMouse ? root.accentColor : Qt.rgba(1,1,1,0.62)
                        font.family: "Inter"
                        font.pixelSize: 13
                        font.bold: true
                        MouseArea {
                            id: scaleUp
                            anchors.fill: parent
                            anchors.margins: -7
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedScale = Math.min(3.0, Math.round((root.selectedScale + 0.05) * 100) / 100)
                                root.applyScale()
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: Qt.rgba(1,1,1,0.08)
                }
            }

            Text {
                x: root.rowX(y - flick.contentY)
                width: root.corridorWidth
                height: 28
                text: "INFORMATION"
                color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.78)
                font.family: "Inter"
                font.pixelSize: 8
                font.bold: true
                font.italic: true
                font.letterSpacing: 1.3
                verticalAlignment: Text.AlignVCenter
            }

            Item {
                id: informationPanel
                x: root.rowX(y - flick.contentY)
                width: root.corridorWidth
                height: 96

                // Information only: no frame and no secondary glass card.
                // Each row follows the parent panel's slanted corridor at its
                // own Y position, so the block stays structurally aligned.
                Repeater {
                    model: [
                        { label: "Connector", value: root.current ? String(root.current.name || "—") : "—" },
                        { label: "Position", value: root.current ? (String(Number(root.current.x || 0)) + " × " + String(Number(root.current.y || 0))) : "—" },
                        { label: "Transform", value: root.current ? String(Number(root.current.transform || 0)) : "—" },
                        { label: "Modes", value: root.current && root.current.availableModes ? String(root.current.availableModes.length) + " available" : "0 available" }
                    ]

                    delegate: Item {
                        required property var modelData
                        required property int index

                        y: index * 22
                        x: -root.slope * (y + height / 2)
                        width: informationPanel.width
                        height: 22

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 92
                            text: modelData.label
                            color: Qt.rgba(1,1,1,0.38)
                            font.family: "Inter"
                            font.pixelSize: 9
                            font.bold: true
                            font.italic: true
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 102
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.value
                            color: modelData.label === "Modes"
                                ? root.accentColor
                                : Qt.rgba(1,1,1,0.72)
                            font.family: "Inter"
                            font.pixelSize: 9
                            font.bold: modelData.label === "Modes"
                            font.italic: true
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Text {
                x: root.rowX(y - flick.contentY)
                width: root.corridorWidth
                height: 48
                wrapMode: Text.WordWrap
                text: "Hyprland supplies the display list. Changes apply immediately and are saved for the next session."
                color: Qt.rgba(1,1,1,0.32)
                font.family: "Inter"
                font.pixelSize: 8
                font.italic: true
                lineHeight: 1.2
            }
        }
    }
}
