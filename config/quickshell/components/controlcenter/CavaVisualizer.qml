import QtQuick
import Quickshell.Io

Item {
    id: root

    property bool active: false
    property int barCount: 24
    property var levels: []
    property bool cavaAvailable: true

    implicitHeight: 25
    visible: active && cavaAvailable

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
        command: ["sh", "-c", "exec cava -p \"$HOME/.config/quickshell/components/controlcenter/cava.conf\""]
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
        spacing: 3

        Repeater {
            model: root.barCount

            Item {
                width: (root.width - (root.barCount - 1) * 3) / root.barCount
                height: root.height

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    width: Math.max(2, parent.width)
                    height: Math.max(2, parent.height * (root.levels.length > index ? root.levels[index] : 0.0))
                    radius: width / 2
                    color: Qt.rgba(55/255, 245/255, 235/255, 0.62)

                    Behavior on height {
                        NumberAnimation { duration: 55; easing.type: Easing.OutQuad }
                    }
                }
            }
        }
    }
}
