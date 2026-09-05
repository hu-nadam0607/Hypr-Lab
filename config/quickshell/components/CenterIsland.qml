import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Notifications
import Quickshell.Services.Mpris
import "controlcenter" as CC

Item {
    id: root

    property color accentColor: "#68787D"
    property bool doNotDisturb: false
    property bool nightLightActive: false
    property bool notificationCenterOpen: false
    property real visualCenterCompensation: 0
    property int unreadNotificationCount: 0

    signal notificationPanelToggleRequested

    // CenterIsland transient layers. Volume, notification summary and the
    // compact CAVA/media views all share the same fixed island surface.
    property bool enableVolumeTransient: true
    property bool enableCavaFace: true
    property bool enableMediaTransient: true
    property bool enableNotificationSummary: true
    property bool enableNotificationSound: true

    readonly property var notificationModel: notificationServer.trackedNotifications
    readonly property int notificationCount: notificationServer.trackedNotifications.values.length
    readonly property bool hasNotifications: notificationCount > 0
    // Always mirror the exact amount shown by the RightBar notification panel.
    // This deliberately does not use unreadNotificationCount, because opening
    // the panel may reset that transient counter while tracked notifications
    // are still present.
    readonly property int notificationSummaryCount: notificationCount

    property var sink: Pipewire.defaultAudioSink
    readonly property var sinkAudio: sink ? sink.audio : null
    readonly property real volumeLevel: sinkAudio ? sinkAudio.volume : 0.0
    readonly property bool muted: sinkAudio ? sinkAudio.muted : true
    property bool audioInitialized: false

    // Minimal CenterIsland CAVA: only alive while an MPRIS player is actually playing.
    property var mediaPlayer: null
    property var mediaPlayers: Mpris.players.values
    readonly property bool musicPlaying: mediaPlayer !== null && mediaPlayer.isPlaying

    function selectPlayingPlayer() {
        const list = Mpris.players.values;
        let selected = null;
        for (let i = 0; i < list.length; ++i) {
            if (list[i] && list[i].isPlaying) {
                selected = list[i];
                break;
            }
        }
        mediaPlayer = selected;
    }

    onMediaPlayersChanged: selectPlayingPlayer()

    Timer {
        interval: 500
        repeat: true
        running: true
        onTriggered: root.selectPlayingPlayer()
    }

    // Transient kinds: "volume", "notification" and "media".
    property string transientKind: ""
    property bool transientShown: false

    width: 240
    height: 36
    implicitWidth: width
    implicitHeight: height
    clip: true

    PwObjectTracker {
        objects: [root.sink]
    }

    readonly property url notificationSoundUrl: Qt.resolvedUrl("../assets/sounds/notification-pop.wav")

    SoundEffect {
        id: notificationPopSound
        source: root.notificationSoundUrl
        volume: 1.0
        loops: 1
    }

    function isDndStatusNotification(notification) {
        return notification && notification.appName === "Hypr-Lab" && (notification.summary === "Ne zavarjanak bekapcsolva." || notification.summary === "Ne zavarjanak kikapcsolva.");
    }

    function announceDndState() {
        Quickshell.execDetached(["notify-send", "-a", "Hypr-Lab", doNotDisturb ? "Ne zavarjanak bekapcsolva." : "Ne zavarjanak kikapcsolva."]);
    }

    function setDnd(enabled, announce, persist) {
        if (announce === undefined)
            announce = true;
        if (persist === undefined)
            persist = true;

        const changed = doNotDisturb !== enabled;
        doNotDisturb = enabled;

        if (persist) {
            // Manual controls (Control Center / IPC) only change the manual
            // override. The schedule itself is configured exclusively in Settings.
            Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/hyprlab-scripts/hyprlab-ui-settings.sh", "set", "DND_MANUAL", enabled ? "1" : "0"]);
        }

        if (announce && changed)
            announceDndState();
    }

    function toggleDnd() {
        setDnd(!doNotDisturb);
    }

    function openNotificationCenter() {
    }
    function closeNotificationCenter() {
        notificationCenterOpen = false;
    }

    function clearAllNotifications() {
        const values = [...notificationServer.trackedNotifications.values];

        for (let i = values.length - 1; i >= 0; --i) {
            if (values[i])
                values[i].dismiss();
        }

        unreadNotificationCount = 0;
    }

    function showTransient(kind, durationMs) {
        transientKind = kind;
        transientHideTimer.interval = durationMs;
        transientShown = true;
        transientHideTimer.restart();
    }

    function showVolumeTransient() {
        if (enableVolumeTransient)
            showTransient("volume", 2000);
    }

    function showNotificationTransient(durationMs) {
        if (enableNotificationSummary)
            showTransient("notification", durationMs || 2000);
    }

    function showMediaTransient() {
        selectPlayingPlayer();
        if (enableMediaTransient && mediaPlayer)
            showTransient("media", 5000);
    }

    NotificationServer {
        id: notificationServer

        bodySupported: true
        bodyMarkupSupported: true
        bodyImagesSupported: true
        imageSupported: true
        actionsSupported: true
        inlineReplySupported: true
        persistenceSupported: true
        keepOnReload: false
        extraHints: ["synchronous", "private-synchronous", "x-canonical-private-synchronous"]

        onNotification: notification => {
            notification.tracked = true;

            const dndStatus = root.isDndStatusNotification(notification);

            if (!dndStatus)
                root.unreadNotificationCount += 1;

            if (root.enableNotificationSound && !root.doNotDisturb && !dndStatus) {
                notificationPopSound.stop();
                notificationPopSound.play();
            }

            if (!dndStatus)
                root.showNotificationTransient(2000);
        }
    }

    IpcHandler {
        target: "notifications"

        function toggle(): void {
            root.notificationPanelToggleRequested();
        }

        function dnd(): void {
            root.toggleDnd();
        }
        function dndOn(): void {
            root.setDnd(true);
        }
        function dndOff(): void {
            root.setDnd(false);
        }
        function clear(): void {
            root.clearAllNotifications();
        }
    }

    SystemClock {
        id: systemClock
        precision: SystemClock.Seconds
    }

    onVolumeLevelChanged: {
        if (!audioInitialized) {
            audioInitialized = true;
            return;
        }
        showVolumeTransient();
    }

    onMutedChanged: {
        if (!audioInitialized) {
            audioInitialized = true;
            return;
        }
        showVolumeTransient();
    }

    Timer {
        id: transientHideTimer
        interval: 2000
        repeat: false
        onTriggered: root.transientShown = false
    }

    // Unified TopBar owns the shared glass/background and the single bottom border.
    // CenterIsland remains a fixed, clipped interaction/transient viewport.

    // Stable base face: tiny 5-bar CAVA + clock / date.
    // The colon only changes opacity, never width, so the surrounding content
    // stays completely still while it blinks once per second.
    Row {
        id: baseFace
        anchors.centerIn: parent
        spacing: root.musicPlaying ? 8 : 0
        opacity: root.transientShown ? 0.0 : 1.0
        visible: opacity > 0.001

        CC.CavaVisualizer {
            id: miniCava
            width: root.musicPlaying ? 20 : 0
            height: 10
            barCount: 5
            active: root.enableCavaFace && root.musicPlaying
            visible: root.enableCavaFace && root.musicPlaying
            barSpacing: 1
            barColor: root.accentColor
            anchors.verticalCenter: parent.verticalCenter

            Behavior on width {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Text {
                text: Qt.formatDateTime(systemClock.date, "HH")
                color: "white"
                font.family: "Inter"
                font.pixelSize: 12
                font.bold: true
                font.italic: true
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: ":"
                opacity: (systemClock.seconds % 2) === 0 ? 1.0 : 0.16
                color: "white"
                font.family: "Inter"
                font.pixelSize: 12
                font.bold: true
                font.italic: true
                anchors.verticalCenter: parent.verticalCenter

                Behavior on opacity {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.InOutSine
                    }
                }
            }

            Text {
                text: Qt.formatDateTime(systemClock.date, "mm")
                color: "white"
                font.family: "Inter"
                font.pixelSize: 12
                font.bold: true
                font.italic: true
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "/"
                color: Qt.rgba(1, 1, 1, 0.52)
                font.family: "Inter"
                font.pixelSize: 11
                font.bold: true
                font.italic: true
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: Qt.formatDateTime(systemClock.date, "yyyy. MM. dd.")
                color: "white"
                font.family: "Inter"
                font.pixelSize: 12
                font.bold: true
                font.italic: true
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "Zz"
                visible: root.doNotDisturb
                color: root.accentColor
                font.family: "Inter"
                font.pixelSize: 9
                font.bold: true
                font.italic: true
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "󰖔"
                visible: root.nightLightActive
                color: root.accentColor
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 170
                easing.type: Easing.InOutCubic
            }
        }
    }

    // All transient content is clipped inside the CenterIsland. Volume keeps
    // its existing right-to-left spring motion, while notification/media use a
    // calm cross-fade so the island itself never jumps or changes size.
    Item {
        id: transientViewport
        x: 20
        y: 2
        width: root.width - 40
        height: root.height - 4
        clip: true
        z: 10

        Item {
            id: volumeFace
            width: transientViewport.width
            height: transientViewport.height
            x: root.transientShown && root.transientKind === "volume" ? 0 : transientViewport.width + 8

            Behavior on x {
                SpringAnimation {
                    spring: 5.5
                    damping: 0.38
                    epsilon: 0.25
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: 9

                Text {
                    text: root.muted ? "󰖁" : "󰕾"
                    color: root.accentColor
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    width: 150
                    height: 14
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 4
                        radius: 2
                        color: Qt.rgba(1, 1, 1, 0.14)
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(0, Math.min(parent.width, (root.muted ? 0 : root.volumeLevel) * parent.width))
                        height: 4
                        radius: 2
                        color: root.accentColor

                        Behavior on width {
                            SpringAnimation {
                                spring: 6
                                damping: 0.46
                                epsilon: 0.2
                            }
                        }
                    }
                }
            }
        }

        Text {
            id: notificationFace
            anchors.centerIn: parent
            width: parent.width
            opacity: root.transientShown && root.transientKind === "notification" ? 1.0 : 0.0
            visible: opacity > 0.001
            text: "Értesítés: " + root.notificationSummaryCount + " db"
            color: "white"
            font.family: "Inter"
            font.pixelSize: 11
            font.bold: true
            font.italic: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.InOutCubic
                }
            }
        }

        Text {
            id: mediaFace
            anchors.centerIn: parent
            width: parent.width
            opacity: root.transientShown && root.transientKind === "media" ? 1.0 : 0.0
            visible: opacity > 0.001
            text: root.mediaPlayer ? ((root.mediaPlayer.trackArtist || "Ismeretlen előadó") + "  /  " + (root.mediaPlayer.trackTitle || "Ismeretlen szám")) : ""
            color: "white"
            font.family: "Inter"
            font.pixelSize: 11
            font.bold: true
            font.italic: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.InOutCubic
                }
            }
        }
    }

    // Wheel gestures are intentionally local to the CenterIsland:
    //   down -> unread notification summary for 3 s
    //   up   -> current artist/title for 5 s
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: false
        z: 50

        onWheel: function (wheel) {
            if (wheel.angleDelta.y < 0) {
                root.showNotificationTransient(3000);
                wheel.accepted = true;
            } else if (wheel.angleDelta.y > 0) {
                root.showMediaTransient();
                wheel.accepted = true;
            }
        }
    }
}
