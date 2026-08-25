import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property int workspaceCount: 10

    property bool topbarWorkspaces: true
    property bool topbarUsb: true
    property bool topbarAudio: true
    property bool topbarNotifications: true
    property bool topbarControlCenter: true
    property bool topbarLockIndicators: true
    property bool topbarTray: true
    property bool topbarPower: true

    property bool centerVolumeFeedback: true
    property bool centerCava: true
    property bool centerMediaFeedback: true

    property bool notificationSound: true
    property bool notificationSummary: true
    property bool dnd: false
    property bool dndAuto: false
    property bool dndManual: false
    property int dndFromMinutes: 1320
    property int dndUntilMinutes: 360

    property real audioVolume: 0.0
    property bool audioMuted: false

    property string statusText: "Ready"

    readonly property string helper:
        Quickshell.env("HOME") + "/.config/hypr/hyprlab-scripts/hyprlab-ui-settings.sh"

    function boolValue(value) {
        return String(value) === "1" || String(value) === "true"
    }

    function setValue(key, value): void {
        const stringValue = String(value)

        Quickshell.execDetached([
            "bash",
            root.helper,
            "set",
            key,
            stringValue
        ])

        root.statusText = "Applied"
        statusTimer.restart()
    }

    function setBool(key, value): void {
        setValue(key, value ? 1 : 0)
    }

    function setDnd(value): void {
        root.dnd = value
        root.setBool("DND", value)
    }

    function setDndAuto(value): void {
        root.dndAuto = value
        root.setBool("DND_AUTO", value)
    }

    function setDndManual(value): void {
        root.dndManual = value
        root.setBool("DND_MANUAL", value)
    }

    function applyDndSchedule(fromMinutes, untilMinutes): void {
        root.dndFromMinutes = Math.max(0, Math.min(1439, fromMinutes))
        root.dndUntilMinutes = Math.max(0, Math.min(1439, untilMinutes))
        root.setValue("DND_FROM", root.dndFromMinutes)
        root.setValue("DND_UNTIL", root.dndUntilMinutes)
        root.statusText = "Applied"
        statusTimer.restart()
    }

    function setWorkspaceCount(value): void {
        const next = Math.max(1, Math.min(10, value))
        root.workspaceCount = next
        root.setValue("WORKSPACE_COUNT", next)
    }

    function switchWorkspace(number): void {
        Quickshell.execDetached([
            "bash",
            root.helper,
            "workspace",
            String(number)
        ])
    }

    function reloadHyprland(): void {
        Quickshell.execDetached(["hyprctl", "reload"])
    }

    function openWelcome(): void {
        Quickshell.execDetached([
            "qs", "ipc", "call", "welcome", "open"
        ])
    }

    function clearNotifications(): void {
        Quickshell.execDetached([
            "qs", "ipc", "call", "notifications", "clear"
        ])
    }

    function openMonitorSettings(): void {
        Quickshell.execDetached([
            "qs", "ipc", "call", "controlcenter", "monitor"
        ])
    }

    function openBrowser(): void {
        Quickshell.execDetached([
            "bash",
            Quickshell.env("HOME") + "/.config/hypr/settings/browser.sh"
        ])
    }

    function openFileManager(): void {
        Quickshell.execDetached([
            "bash",
            Quickshell.env("HOME") + "/.config/hypr/settings/filemanager.sh"
        ])
    }

    function openCalculator(): void {
        Quickshell.execDetached([
            "bash",
            Quickshell.env("HOME") + "/.config/hypr/settings/calculator.sh"
        ])
    }

    function openAudioSettings(): void {
        Quickshell.execDetached(["pavucontrol"])
    }

    function reload(): void {
        if (!loadProc.running)
            loadProc.running = true
    }

    function refreshAudio(): void {
        if (!audioProbe.running)
            audioProbe.running = true
    }

    function changeAudioVolume(deltaPercent): void {
        const step = Math.abs(deltaPercent) + "%"

        Quickshell.execDetached([
            "wpctl",
            "set-volume",
            "-l",
            "1.5",
            "@DEFAULT_AUDIO_SINK@",
            deltaPercent < 0 ? step + "-" : step + "+"
        ])

        audioRefresh.restart()
    }

    function setAudioMuted(value): void {
        root.audioMuted = value

        Quickshell.execDetached([
            "wpctl",
            "set-mute",
            "@DEFAULT_AUDIO_SINK@",
            value ? "1" : "0"
        ])

        audioRefresh.restart()
    }

    Process {
        id: loadProc

        command: [
            "bash",
            root.helper,
            "dump"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const raw = String(text).trim()
                if (raw.length === 0)
                    return

                const lines = raw.split("\n")

                for (let line of lines) {
                    const index = line.indexOf("=")
                    if (index < 1)
                        continue

                    const key = line.slice(0, index)
                    const value = line.slice(index + 1)

                    if (key === "WORKSPACE_COUNT")
                        root.workspaceCount = Math.max(1, Math.min(10, parseInt(value)))
                    else if (key === "TOPBAR_WORKSPACES")
                        root.topbarWorkspaces = root.boolValue(value)
                    else if (key === "TOPBAR_USB")
                        root.topbarUsb = root.boolValue(value)
                    else if (key === "TOPBAR_AUDIO")
                        root.topbarAudio = root.boolValue(value)
                    else if (key === "TOPBAR_NOTIFICATIONS")
                        root.topbarNotifications = root.boolValue(value)
                    else if (key === "TOPBAR_CONTROL_CENTER")
                        root.topbarControlCenter = root.boolValue(value)
                    else if (key === "TOPBAR_LOCK_INDICATORS")
                        root.topbarLockIndicators = root.boolValue(value)
                    else if (key === "TOPBAR_TRAY")
                        root.topbarTray = root.boolValue(value)
                    else if (key === "TOPBAR_POWER")
                        root.topbarPower = root.boolValue(value)
                    else if (key === "CENTER_VOLUME_FEEDBACK")
                        root.centerVolumeFeedback = root.boolValue(value)
                    else if (key === "CENTER_CAVA")
                        root.centerCava = root.boolValue(value)
                    else if (key === "CENTER_MEDIA_FEEDBACK")
                        root.centerMediaFeedback = root.boolValue(value)
                    else if (key === "NOTIFICATION_SOUND")
                        root.notificationSound = root.boolValue(value)
                    else if (key === "NOTIFICATION_SUMMARY")
                        root.notificationSummary = root.boolValue(value)
                    else if (key === "DND")
                        root.dnd = root.boolValue(value)
                    else if (key === "DND_AUTO")
                        root.dndAuto = root.boolValue(value)
                    else if (key === "DND_MANUAL")
                        root.dndManual = root.boolValue(value)
                    else if (key === "DND_FROM")
                        root.dndFromMinutes = Math.max(0, Math.min(1439, parseInt(value)))
                    else if (key === "DND_UNTIL")
                        root.dndUntilMinutes = Math.max(0, Math.min(1439, parseInt(value)))
                }
            }
        }
    }

    Process {
        id: audioProbe

        command: [
            "wpctl",
            "get-volume",
            "@DEFAULT_AUDIO_SINK@"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const raw = String(text).trim()
                const match = raw.match(/Volume:\s*([0-9.]+)/)

                if (match)
                    root.audioVolume = Math.max(0, Math.min(1.5, parseFloat(match[1])))

                root.audioMuted = raw.indexOf("[MUTED]") >= 0
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 180
        repeat: false
        onTriggered: root.reload()
    }

    Timer {
        id: audioRefresh
        interval: 180
        repeat: false
        onTriggered: root.refreshAudio()
    }

    Timer {
        id: statusTimer
        interval: 1400
        repeat: false
        onTriggered: root.statusText = "Ready"
    }

    Component.onCompleted: {
        root.reload()
        root.refreshAudio()
    }
}
