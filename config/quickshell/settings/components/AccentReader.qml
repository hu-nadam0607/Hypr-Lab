import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property color accentColor: "#68787D"
    property string accentHex: "68787D"

    function refresh(): void {
        if (!reader.running)
            reader.running = true
    }

    Process {
        id: reader
        command: [
            "sh",
            "-c",
            'f="$HOME/.cache/hypr-lab/border-color"; if [ -s "$f" ]; then cat "$f"; else printf "68787D\\n"; fi'
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim().replace(/^#/, "")
                if (/^[0-9A-Fa-f]{6}$/.test(v) && v.toUpperCase() !== root.accentHex) {
                    root.accentHex = v.toUpperCase()
                    root.accentColor = "#" + root.accentHex
                }
            }
        }
    }

    Timer {
        interval: 1200
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
