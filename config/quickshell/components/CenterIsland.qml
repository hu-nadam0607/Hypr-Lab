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
    property bool notificationCenterOpen: false
    property real visualCenterCompensation: 0
    property int unreadNotificationCount: 0

    // Feature switches kept deliberately. Volume is re-enabled now; CAVA and
    // notification-summary stay in the source as the next restore points.
    property bool enableVolumeTransient: true
    property bool enableCavaFace: true
    property bool enableNotificationSummary: false

    readonly property var notificationModel: notificationServer.trackedNotifications
    readonly property int notificationCount: notificationServer.trackedNotifications.values.length
    readonly property bool hasNotifications: notificationCount > 0

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
        const list = Mpris.players.values
        let selected = null
        for (let i = 0; i < list.length; ++i) {
            if (list[i] && list[i].isPlaying) {
                selected = list[i]
                break
            }
        }
        mediaPlayer = selected
    }

    onMediaPlayersChanged: selectPlayingPlayer()

    Timer {
        interval: 500
        repeat: true
        running: true
        onTriggered: root.selectPlayingPlayer()
    }

    // Reserved transient kinds: "volume" is active now; "notification" stays
    // wired in code but intentionally dormant until we restore that layer.
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
        return notification
            && notification.appName === "Hypr-Lab"
            && (notification.summary === "Ne zavarjanak bekapcsolva."
                || notification.summary === "Ne zavarjanak kikapcsolva.")
    }

    function announceDndState() {
        Quickshell.execDetached([
            "notify-send",
            "-a", "Hypr-Lab",
            doNotDisturb
                ? "Ne zavarjanak bekapcsolva."
                : "Ne zavarjanak kikapcsolva."
        ])
    }

    function setDnd(enabled) {
        if (doNotDisturb === enabled)
            return

        doNotDisturb = enabled
        announceDndState()
    }

    function toggleDnd() {
        setDnd(!doNotDisturb)
    }

    function openNotificationCenter() {}
    function closeNotificationCenter() { notificationCenterOpen = false }

    function clearAllNotifications() {
        const values = [...notificationServer.trackedNotifications.values]

        for (let i = values.length - 1; i >= 0; --i) {
            if (values[i])
                values[i].dismiss()
        }

        unreadNotificationCount = 0
    }

    function showTransient(kind) {
        transientKind = kind
        transientShown = true
        transientHideTimer.restart()
    }

    function showVolumeTransient() {
        if (enableVolumeTransient)
            showTransient("volume")
    }

    // Kept for the next step. It is intentionally not called by the
    // NotificationServer while enableNotificationSummary is false.
    function showNotificationTransient() {
        if (enableNotificationSummary)
            showTransient("notification")
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
        extraHints: [
            "synchronous",
            "private-synchronous",
            "x-canonical-private-synchronous"
        ]

        onNotification: notification => {
            notification.tracked = true

            const dndStatus = root.isDndStatusNotification(notification)

            if (!dndStatus)
                root.unreadNotificationCount += 1

            if (!root.doNotDisturb && !dndStatus) {
                notificationPopSound.stop()
                notificationPopSound.play()
            }

            if (!dndStatus)
                root.showNotificationTransient()
        }
    }

    IpcHandler {
        target: "notifications"

        function toggle(): void {}
        function dnd(): void { root.toggleDnd() }
        function dndOn(): void { root.setDnd(true) }
        function dndOff(): void { root.setDnd(false) }
    }

    SystemClock {
        id: systemClock
        precision: SystemClock.Seconds
    }

    onVolumeLevelChanged: {
        if (!audioInitialized) {
            audioInitialized = true
            return
        }
        showVolumeTransient()
    }

    onMutedChanged: {
        if (!audioInitialized) {
            audioInitialized = true
            return
        }
        showVolumeTransient()
    }

    Timer {
        id: transientHideTimer
        interval: 2000
        repeat: false
        onTriggered: root.transientShown = false
    }

    Capsule {
        anchors.fill: parent
        capsuleWidth: root.width
        capsuleHeight: root.height
        borderWidth: 2
        borderColor: Qt.rgba(
            root.accentColor.r,
            root.accentColor.g,
            root.accentColor.b,
            0.90
        )
        shadowStrength: 0.38
    }

    // Stable base face: tiny 5-bar CAVA + clock / date. The colon blinks on system seconds.
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
                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
            }
        }

        Text {
            text: Qt.formatDateTime(systemClock.date, "HH")
                  + ((systemClock.seconds % 2) === 0 ? ":" : " ")
                  + Qt.formatDateTime(systemClock.date, "mm")
                  + "  /  "
                  + Qt.formatDateTime(systemClock.date, "yyyy. MM. dd.")
            color: "white"
            font.family: "Inter"
            font.pixelSize: 12
            font.bold: true
            font.italic: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
        }

        Behavior on opacity {
            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
        }
    }

    // Transient viewport: deliberately inset from BOTH slanted edges.
    // The moving face is clipped here, so it never becomes visible outside
    // the CenterIsland border while entering/exiting from the right.
    Item {
        id: transientViewport
        x: 20
        y: 2
        width: root.width - 40
        height: root.height - 4
        clip: true
        z: 10

        // Volume strip: slides only INSIDE the CenterIsland, follows volume
        // changes fluidly, waits two seconds, then exits inside to the right.
        Item {
            id: transientFace
            width: transientViewport.width
            height: transientViewport.height
            x: root.transientShown ? 0 : transientViewport.width + 8

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
                visible: root.transientKind === "volume"

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
                    color: Qt.rgba(1,1,1,0.14)
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(
                        0,
                        Math.min(
                            parent.width,
                            (root.muted ? 0 : root.volumeLevel) * parent.width
                        )
                    )
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

        // Notification summary stays in code for the next restore step.
            Text {
                anchors.centerIn: parent
                visible: root.transientKind === "notification"
                text: "Új értesítés: " + root.unreadNotificationCount + " db"
                color: "white"
                font.family: "Inter"
                font.pixelSize: 11
                font.bold: true
                font.italic: true
            }
        }
    }

}
