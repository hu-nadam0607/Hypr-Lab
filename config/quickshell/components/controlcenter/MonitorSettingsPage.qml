import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: root

    signal backRequested()
    signal closeRequested()

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

    function script() {
        return Quickshell.env("HOME")
            + "/.config/hypr/hyprlab-scripts/hyprlab-settings.sh"
    }

    function refresh() {
        if (!monitorProc.running)
            monitorProc.running = true
    }

    function normalizedMode(value) {
        return String(value || "")
            .replace(/Hz$/, "")
            .replace(/\.0+$/, "")
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

        const wantedRes =
            Number(current.width || 0)
            + "x"
            + Number(current.height || 0)

        let nearest = 0
        let nearestDelta = 999999
        const currentRefresh = Number(current.refreshRate || 0)

        for (let i = 0; i < current.availableModes.length; ++i) {
            const mode = String(current.availableModes[i])
            if (mode.indexOf(wantedRes + "@") !== 0)
                continue

            const refreshText =
                mode.substring(mode.indexOf("@") + 1).replace(/Hz$/, "")
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
        const position =
            String(Number(current.x || 0))
            + "x"
            + String(Number(current.y || 0))

        Quickshell.execDetached([
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
            script(),
            "monitor-scale",
            String(current.name),
            String(selectedScale)
        ])

        refreshDelay.restart()
    }

    Process {
        id: monitorProc
        command: [root.script(), "monitors"]

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
                    console.warn(
                        "Hypr-Lab Monitor Settings: failed to parse hyprctl JSON:",
                        error
                    )
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

    SettingsHeader {
        id: header

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top

        title: "MONITOR & DISPLAY"
        subtitle: "Hyprland detected outputs"

        onBackRequested: root.backRequested()
        onCloseRequested: root.closeRequested()
    }

    Flickable {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: 8

        contentWidth: width
        contentHeight: content.implicitHeight + 12
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: content
            width: parent.width
            spacing: 9

            Text {
                text: "CONNECTED DISPLAY"
                color: Qt.rgba(190/255, 205/255, 210/255, 0.52)
                font.family: "Inter"
                font.pixelSize: 9
                font.bold: true
                font.letterSpacing: 1.6
            }

            Rectangle {
                width: parent.width
                height: 88
                radius: 19

                color: Qt.rgba(1, 1, 1, 0.04)
                border.width: 1
                border.color: Qt.rgba(55/255, 245/255, 235/255, 0.20)

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.right: monitorSwitch.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        text: root.current
                            ? String(root.current.name || "Unknown output")
                            : "No display detected"

                        color: "#37f5eb"
                        font.family: "Inter"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Text {
                        width: parent.width
                        text: root.current
                            ? String(
                                root.current.description
                                || (
                                    String(root.current.make || "")
                                    + " "
                                    + String(root.current.model || "")
                                )
                            )
                            : "Hyprland did not report an output"

                        color: Qt.rgba(1, 1, 1, 0.48)
                        font.family: "Inter"
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }

                    Text {
                        text: root.current
                            ? (
                                root.currentModeString(root.current)
                                + " · scale "
                                + Number(root.current.scale || 1).toFixed(2)
                            )
                            : ""

                        color: Qt.rgba(1, 1, 1, 0.68)
                        font.family: "Inter"
                        font.pixelSize: 9
                    }
                }

                Rectangle {
                    id: monitorSwitch

                    visible: root.monitors.length > 1
                    width: 52
                    height: 28
                    radius: 14

                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter

                    color: Qt.rgba(55/255, 245/255, 235/255, 0.10)
                    border.width: 1
                    border.color: Qt.rgba(55/255, 245/255, 235/255, 0.28)

                    Text {
                        anchors.centerIn: parent
                        text: (root.selectedIndex + 1) + "/" + root.monitors.length
                        color: "#37f5eb"
                        font.family: "Inter"
                        font.pixelSize: 9
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            modeSelector.expanded = false
                            root.selectMonitor(
                                (root.selectedIndex + 1) % root.monitors.length
                            )
                        }
                    }
                }
            }

            Text {
                text: "RESOLUTION & REFRESH"
                topPadding: 5
                color: Qt.rgba(190/255, 205/255, 210/255, 0.52)
                font.family: "Inter"
                font.pixelSize: 9
                font.bold: true
                font.letterSpacing: 1.6
            }

            Rectangle {
                id: modeSelector

                property bool expanded: false

                width: parent.width
                height: 64
                radius: 17

                color: Qt.rgba(1, 1, 1, 0.035)
                border.width: 1
                border.color: modeMouse.containsMouse
                    ? Qt.rgba(55/255, 245/255, 235/255, 0.30)
                    : Qt.rgba(1, 1, 1, 0.055)

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 165
                    spacing: 2

                    Text {
                        text: "Display mode"
                        color: "#e7f1f2"
                        font.family: "Inter"
                        font.pixelSize: 11
                        font.bold: true
                    }

                    Text {
                        text: "Resolution and refresh rate"
                        color: Qt.rgba(1, 1, 1, 0.40)
                        font.family: "Inter"
                        font.pixelSize: 9
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter

                    width: 140
                    height: 34
                    radius: 17

                    color: modeSelector.expanded
                        ? Qt.rgba(55/255, 245/255, 235/255, 0.16)
                        : Qt.rgba(55/255, 245/255, 235/255, 0.10)

                    border.width: 1
                    border.color: modeSelector.expanded
                        ? Qt.rgba(55/255, 245/255, 235/255, 0.58)
                        : Qt.rgba(55/255, 245/255, 235/255, 0.28)

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text:
                                root.current
                                && root.current.availableModes
                                && root.current.availableModes.length > 0
                                ? String(root.current.availableModes[root.modeIndex])
                                : "—"

                            color: "#37f5eb"
                            font.family: "Inter"
                            font.pixelSize: 9
                            font.bold: true
                        }

                        Text {
                            text: modeSelector.expanded ? "󰅃" : "󰅀"
                            color: Qt.rgba(1, 1, 1, 0.62)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                        }
                    }
                }

                MouseArea {
                    id: modeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        if (
                            root.current
                            && root.current.availableModes
                            && root.current.availableModes.length > 0
                        ) {
                            modeSelector.expanded = !modeSelector.expanded
                        }
                    }
                }
            }

            Rectangle {
                id: modeDropdown

                visible: modeSelector.expanded
                width: parent.width
                height: visible
                    ? Math.min(
                        220,
                        12 + modeList.contentHeight
                    )
                    : 0

                radius: 17
                color: Qt.rgba(10/255, 15/255, 21/255, 0.96)
                border.width: 1
                border.color: Qt.rgba(55/255, 245/255, 235/255, 0.28)
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
                    anchors.margins: 6

                    clip: true
                    spacing: 4

                    model:
                        root.current && root.current.availableModes
                        ? root.current.availableModes
                        : []

                    delegate: Rectangle {
                        required property string modelData
                        required property int index

                        width: modeList.width
                        height: 38
                        radius: 12

                        color:
                            index === root.modeIndex
                            ? Qt.rgba(55/255, 245/255, 235/255, 0.14)
                            : modeItemMouse.containsMouse
                                ? Qt.rgba(1, 1, 1, 0.07)
                                : "transparent"

                        border.width: index === root.modeIndex ? 1 : 0
                        border.color: Qt.rgba(
                            55/255,
                            245/255,
                            235/255,
                            0.34
                        )

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter

                            text: modelData
                            color:
                                index === root.modeIndex
                                ? "#37f5eb"
                                : "#dce8e9"

                            font.family: "Inter"
                            font.pixelSize: 10
                            font.bold: index === root.modeIndex
                        }

                        Text {
                            visible: index === root.modeIndex
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter

                            text: "󰄬"
                            color: "#37f5eb"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                        }

                        MouseArea {
                            id: modeItemMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                root.modeIndex = index
                                modeSelector.expanded = false
                                root.applyMode()
                            }
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: modeList.contentHeight > modeList.height
                            ? ScrollBar.AsNeeded
                            : ScrollBar.AlwaysOff
                    }
                }
            }

            SettingStepper {
                title: "Scale"
                subtitle: "Logical display scaling"
                valueText: root.selectedScale.toFixed(2) + "×"

                onDecrease: {
                    root.selectedScale =
                        Math.max(
                            0.5,
                            Math.round((root.selectedScale - 0.05) * 100) / 100
                        )

                    root.applyScale()
                }

                onIncrease: {
                    root.selectedScale =
                        Math.min(
                            3.0,
                            Math.round((root.selectedScale + 0.05) * 100) / 100
                        )

                    root.applyScale()
                }
            }

            Text {
                text: "INFORMATION"
                topPadding: 5
                color: Qt.rgba(190/255, 205/255, 210/255, 0.52)
                font.family: "Inter"
                font.pixelSize: 9
                font.bold: true
                font.letterSpacing: 1.6
            }

            Rectangle {
                width: parent.width
                height: 112
                radius: 17
                color: Qt.rgba(1, 1, 1, 0.03)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.05)

                Column {
                    anchors.fill: parent
                    anchors.margins: 13
                    spacing: 7

                    Text {
                        text: root.current
                            ? "Connector   " + String(root.current.name || "—")
                            : ""

                        color: Qt.rgba(1, 1, 1, 0.58)
                        font.family: "Inter"
                        font.pixelSize: 10
                    }

                    Text {
                        text: root.current
                            ? (
                                "Position    "
                                + Number(root.current.x || 0)
                                + " × "
                                + Number(root.current.y || 0)
                            )
                            : ""

                        color: Qt.rgba(1, 1, 1, 0.58)
                        font.family: "Inter"
                        font.pixelSize: 10
                    }

                    Text {
                        text: root.current
                            ? "Transform   " + String(root.current.transform || 0)
                            : ""

                        color: Qt.rgba(1, 1, 1, 0.58)
                        font.family: "Inter"
                        font.pixelSize: 10
                    }

                    Text {
                        text:
                            root.current && root.current.availableModes
                            ? root.current.availableModes.length + " available modes"
                            : ""

                        color: Qt.rgba(55/255, 245/255, 235/255, 0.70)
                        font.family: "Inter"
                        font.pixelSize: 10
                    }
                }
            }

            Text {
                width: parent.width
                wrapMode: Text.WordWrap

                text:
                    "Hyprland supplies the display list, so DP, HDMI, eDP and "
                    + "USB-C outputs are handled identically. Changes apply "
                    + "immediately and are saved for the next session."

                color: Qt.rgba(1, 1, 1, 0.34)
                font.family: "Inter"
                font.pixelSize: 9
                lineHeight: 1.25
            }
        }
    }
}
