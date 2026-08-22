import QtQuick
import Quickshell.Io

Item {
    id: root

    property bool active: false
    property int barCount: 24
    property var levels: []
    property bool cavaAvailable: true
    property real barSpacing: 3
    property color barColor: Qt.rgba(1, 1, 1, 0.30)

    implicitHeight: 25
    visible: cavaAvailable

    function setFrame(line) {
        const raw = line.trim()
        if (!raw.length)
            return

        const parts = raw.split(";")
        const next = []

        for (let i = 0; i < Math.min(parts.length, barCount); ++i) {
            const n = Number(parts[i])
            next.push(isNaN(n) ? 0 : Math.max(0, Math.min(1, n / 100.0)))
        }

        while (next.length < barCount)
            next.push(0)

        levels = next
    }

    Process {
        id: cavaProbe
        command: ["sh", "-c", "command -v cava >/dev/null 2>&1"]
        running: true

        onExited: (exitCode, exitStatus) => {
            root.cavaAvailable = exitCode === 0
            if (root.cavaAvailable && root.active)
                cavaProcess.running = true
        }
    }

    Process {
        id: cavaProcess
        command: [
            "sh",
            "-c",
            "exec cava -p \"$HOME/.config/quickshell/lock/components/cava.conf\""
        ]
        running: false

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => root.setFrame(data)
        }

        onRunningChanged: {
            if (!running && root.active && root.cavaAvailable)
                restartDelay.restart()
        }
    }

    Timer {
        id: restartDelay
        interval: 500
        repeat: false

        onTriggered: {
            if (root.active && root.cavaAvailable && !cavaProcess.running)
                cavaProcess.running = true
        }
    }

    onActiveChanged: {
        if (!cavaAvailable)
            return

        if (active) {
            if (!cavaProcess.running)
                cavaProcess.running = true
        } else {
            restartDelay.stop()
            cavaProcess.running = false
            levels = []
        }
    }

    Row {
        anchors.fill: parent
        spacing: root.barSpacing

        Repeater {
            model: root.barCount

            Item {
                width:
                    (root.width - (root.barCount - 1) * root.barSpacing)
                    / root.barCount
                height: root.height

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom

                    width: Math.max(2, parent.width)

                    height:
                        root.active
                        ? Math.max(
                              2,
                              parent.height
                              * (
                                    root.levels.length > index
                                    ? root.levels[index]
                                    : 0.0
                                )
                          )
                        : 2

                    radius: 1
                    color: root.barColor

                    Behavior on height {
                        NumberAnimation {
                            duration: 55
                            easing.type: Easing.OutQuad
                        }
                    }
                }
            }
        }
    }
}
