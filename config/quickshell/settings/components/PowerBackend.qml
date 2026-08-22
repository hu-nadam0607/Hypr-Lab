import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property bool autoLock: true
    property int lockMinutes: 5
    property bool displayOff: true
    property int displayOffAfterLock: 5
    property bool suspendEnabled: true
    property int suspendAfterLock: 20

    property string statusText: "Ready"
    property bool loading: false

    readonly property string helper:
        Quickshell.env("HOME") + "/.config/hypr/hyprlab-scripts/hyprlab-power-settings.sh"

    function reload(): void {
        if (!loadProcess.running) {
            loading = true
            loadProcess.running = true
        }
    }

    function setValue(key, value): void {
        Quickshell.execDetached([
            "bash",
            helper,
            "set",
            key,
            String(value)
        ])
        statusText = "Applied"
        appliedTimer.restart()
    }

    function setAutoLock(value): void {
        autoLock = value
        setValue("AUTO_LOCK", value ? 1 : 0)
    }

    function setLockMinutes(value): void {
        lockMinutes = Math.max(1, Math.min(120, value))
        setValue("LOCK_MINUTES", lockMinutes)
    }

    function setDisplayOff(value): void {
        displayOff = value
        setValue("DISPLAY_OFF", value ? 1 : 0)
    }

    function setDisplayOffAfterLock(value): void {
        displayOffAfterLock = Math.max(1, Math.min(120, value))
        setValue("DISPLAY_OFF_AFTER_LOCK", displayOffAfterLock)
    }

    function setSuspendEnabled(value): void {
        suspendEnabled = value
        setValue("SUSPEND", value ? 1 : 0)
    }

    function setSuspendAfterLock(value): void {
        suspendAfterLock = Math.max(1, Math.min(360, value))
        setValue("SUSPEND_AFTER_LOCK", suspendAfterLock)
    }

    Process {
        id: loadProcess
        command: ["bash", root.helper, "dump"]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                for (let line of lines) {
                    const idx = line.indexOf("=")
                    if (idx < 1)
                        continue
                    const key = line.slice(0, idx)
                    const value = line.slice(idx + 1)

                    if (key === "AUTO_LOCK") root.autoLock = value === "1"
                    else if (key === "LOCK_MINUTES") root.lockMinutes = parseInt(value)
                    else if (key === "DISPLAY_OFF") root.displayOff = value === "1"
                    else if (key === "DISPLAY_OFF_AFTER_LOCK") root.displayOffAfterLock = parseInt(value)
                    else if (key === "SUSPEND") root.suspendEnabled = value === "1"
                    else if (key === "SUSPEND_AFTER_LOCK") root.suspendAfterLock = parseInt(value)
                }
                root.loading = false
                root.statusText = "Ready"
            }
        }
    }

    Timer {
        id: appliedTimer
        interval: 1400
        repeat: false
        onTriggered: root.statusText = "Ready"
    }

    Component.onCompleted: reload()
}
