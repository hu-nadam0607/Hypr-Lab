import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property int workspaceCount: 10
    property bool showWorkspaces: true
    property bool showUsb: true
    property bool showAudio: true
    property bool showNotifications: true
    property bool showControlCenter: true
    property bool showLockIndicators: true
    property bool showTray: true
    property bool showPower: true
    property bool volumeFeedback: true
    property bool cavaFace: true
    property bool mediaFeedback: true
    property bool notificationSound: true
    property bool notificationSummary: true
    property bool dndEnabled: false

    readonly property string helper:
        Quickshell.env("HOME") + "/.config/hypr/hyprlab-scripts/hyprlab-ui-settings.sh"

    function boolValue(value) {
        return String(value) === "1" || String(value) === "true"
    }

    function refresh(): void {
        if (!reader.running)
            reader.running = true
    }

    function applyDump(raw): void {
        const textValue = String(raw).trim()
        if (textValue.length === 0)
            return

        const lines = textValue.split("\n")

        for (let line of lines) {
            const pos = line.indexOf("=")
            if (pos < 1)
                continue

            const key = line.slice(0, pos)
            const value = line.slice(pos + 1)

            if (key === "WORKSPACE_COUNT")
                workspaceCount = Math.max(1, Math.min(10, parseInt(value)))
            else if (key === "TOPBAR_WORKSPACES")
                showWorkspaces = boolValue(value)
            else if (key === "TOPBAR_USB")
                showUsb = boolValue(value)
            else if (key === "TOPBAR_AUDIO")
                showAudio = boolValue(value)
            else if (key === "TOPBAR_NOTIFICATIONS")
                showNotifications = boolValue(value)
            else if (key === "TOPBAR_CONTROL_CENTER")
                showControlCenter = boolValue(value)
            else if (key === "TOPBAR_LOCK_INDICATORS")
                showLockIndicators = boolValue(value)
            else if (key === "TOPBAR_TRAY")
                showTray = boolValue(value)
            else if (key === "TOPBAR_POWER")
                showPower = boolValue(value)
            else if (key === "CENTER_VOLUME_FEEDBACK")
                volumeFeedback = boolValue(value)
            else if (key === "CENTER_CAVA")
                cavaFace = boolValue(value)
            else if (key === "CENTER_MEDIA_FEEDBACK")
                mediaFeedback = boolValue(value)
            else if (key === "NOTIFICATION_SOUND")
                notificationSound = boolValue(value)
            else if (key === "NOTIFICATION_SUMMARY")
                notificationSummary = boolValue(value)
            else if (key === "DND")
                dndEnabled = boolValue(value)
        }
    }

    Process {
        id: reader
        command: ["bash", root.helper, "dump"]

        stdout: StdioCollector {
            onStreamFinished: root.applyDump(text)
        }
    }

    Timer {
        interval: 250
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
