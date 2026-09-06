import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string accentHex: "68787D"
    readonly property color accentColor: "#" + accentHex
    property int refreshInterval: 350

    visible: false
    width: 0
    height: 0

    function refresh(): void {
        if (!reader.running)
            reader.running = true
    }

    Process {
        id: reader
        command: [
            "sh", "-c",
            "f=\"$HOME/.cache/hypr-lab/border-color\"; "
            + "if [ -s \"$f\" ]; then cat \"$f\"; else printf '68787D\\n'; fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim().replace(/^#/, "")
                if (/^[0-9A-Fa-f]{6}$/.test(value))
                    root.accentHex = value.toUpperCase()
            }
        }
    }

    Timer {
        interval: root.refreshInterval
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
