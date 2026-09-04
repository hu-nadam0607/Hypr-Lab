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
    property bool dndAuto: false
    property bool dndManual: false
    property int dndFromMinutes: 1320
    property int dndUntilMinutes: 360

    property bool nightLightAuto: false
    property bool nightLightManual: false
    property int nightLightFromMinutes: 1200
    property int nightLightUntilMinutes: 420
    property int nightLightTemperature: 4500

    property var lastNightLightEnabled: undefined
    property int lastNightLightTemperature: -1

    readonly property int currentMinutes: parseInt(Qt.formatDateTime(clock.date, "HH")) * 60 + parseInt(Qt.formatDateTime(clock.date, "mm"))
    readonly property bool dndScheduledNow: {
        if (!dndAuto || dndFromMinutes === dndUntilMinutes)
            return false;
        if (dndFromMinutes < dndUntilMinutes)
            return currentMinutes >= dndFromMinutes && currentMinutes < dndUntilMinutes;
        return currentMinutes >= dndFromMinutes || currentMinutes < dndUntilMinutes;
    }
    readonly property bool effectiveDnd: dndManual || dndScheduledNow

    readonly property bool nightLightScheduledNow: {
        if (!nightLightAuto || nightLightFromMinutes === nightLightUntilMinutes)
            return false;
        if (nightLightFromMinutes < nightLightUntilMinutes)
            return currentMinutes >= nightLightFromMinutes && currentMinutes < nightLightUntilMinutes;
        return currentMinutes >= nightLightFromMinutes || currentMinutes < nightLightUntilMinutes;
    }

    readonly property bool effectiveNightLight: nightLightManual || nightLightScheduledNow

    readonly property string helper: Quickshell.env("HOME") + "/.config/hypr/hyprlab-scripts/hyprlab-ui-settings.sh"

    function boolValue(value) {
        return String(value) === "1" || String(value) === "true";
    }

    function refresh(): void {
        if (!reader.running)
            reader.running = true;
    }

    function syncNightLight(): void {
        const enabled = root.effectiveNightLight;
        const temperature = root.nightLightTemperature;

        if (root.lastNightLightEnabled === enabled && (!enabled || root.lastNightLightTemperature === temperature))
            return;

        if (enabled) {
            Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", String(temperature)]);
        } else {
            Quickshell.execDetached(["hyprctl", "hyprsunset", "identity"]);
        }

        root.lastNightLightEnabled = enabled;
        root.lastNightLightTemperature = temperature;
    }

    function applyDump(raw): void {
        const textValue = String(raw).trim();
        if (textValue.length === 0)
            return;
        const lines = textValue.split("\n");

        for (let line of lines) {
            const pos = line.indexOf("=");
            if (pos < 1)
                continue;
            const key = line.slice(0, pos);
            const value = line.slice(pos + 1);

            if (key === "WORKSPACE_COUNT")
                workspaceCount = Math.max(1, Math.min(10, parseInt(value)));
            else if (key === "TOPBAR_WORKSPACES")
                showWorkspaces = boolValue(value);
            else if (key === "TOPBAR_USB")
                showUsb = boolValue(value);
            else if (key === "TOPBAR_AUDIO")
                showAudio = boolValue(value);
            else if (key === "TOPBAR_NOTIFICATIONS")
                showNotifications = boolValue(value);
            else if (key === "TOPBAR_CONTROL_CENTER")
                showControlCenter = boolValue(value);
            else if (key === "TOPBAR_LOCK_INDICATORS")
                showLockIndicators = boolValue(value);
            else if (key === "TOPBAR_TRAY")
                showTray = boolValue(value);
            else if (key === "TOPBAR_POWER")
                showPower = boolValue(value);
            else if (key === "CENTER_VOLUME_FEEDBACK")
                volumeFeedback = boolValue(value);
            else if (key === "CENTER_CAVA")
                cavaFace = boolValue(value);
            else if (key === "CENTER_MEDIA_FEEDBACK")
                mediaFeedback = boolValue(value);
            else if (key === "NOTIFICATION_SOUND")
                notificationSound = boolValue(value);
            else if (key === "NOTIFICATION_SUMMARY")
                notificationSummary = boolValue(value);
            else if (key === "DND")
                dndEnabled = boolValue(value);
            else if (key === "DND_AUTO")
                dndAuto = boolValue(value);
            else if (key === "DND_MANUAL")
                dndManual = boolValue(value);
            else if (key === "DND_FROM")
                dndFromMinutes = Math.max(0, Math.min(1439, parseInt(value)));
            else if (key === "DND_UNTIL")
                dndUntilMinutes = Math.max(0, Math.min(1439, parseInt(value)));
            else if (key === "NIGHT_LIGHT_AUTO")
                nightLightAuto = boolValue(value);
            else if (key === "NIGHT_LIGHT_MANUAL")
                nightLightManual = boolValue(value);
            else if (key === "NIGHT_LIGHT_FROM")
                nightLightFromMinutes = Math.max(0, Math.min(1439, parseInt(value)));
            else if (key === "NIGHT_LIGHT_UNTIL")
                nightLightUntilMinutes = Math.max(0, Math.min(1439, parseInt(value)));
            else if (key === "NIGHT_LIGHT_TEMPERATURE")
                nightLightTemperature = Math.max(1000, Math.min(20000, parseInt(value)));
        }

        root.syncNightLight();
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
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
