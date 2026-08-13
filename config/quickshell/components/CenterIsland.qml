import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications

Item {
    id: root

    // ============================================================
    // DO NOT DISTURB / UNREAD STATE
    // ============================================================

    // Egyetlen közös DND state: ezt használja a Control Center és az IPC bind is.
    property bool doNotDisturb: false

    // A piros pötty nem a teljes history-t, hanem az olvasatlan állapotot jelzi.
    // A Notification Center megnyitása "elolvasásnak" számít.
    property int unreadNotificationCount: 0

    // ============================================================
    // NOTIFICATION SOUND
    // ============================================================

    property bool notificationSoundReady: false
    property bool notificationSoundWarmupRunning: false
    property bool notificationSoundPending: false
    property bool notificationSoundReloadPending: false

    readonly property url notificationSoundUrl:
        Qt.resolvedUrl("../assets/sounds/notification-pop.wav")

    // One persistent low-latency player. It is NOT warmed up until PipeWire
    // already exposes a default sink and QtMultimedia has loaded the WAV.
    SoundEffect {
        id: notificationPopSound

        source: root.notificationSoundUrl
        volume: root.notificationSoundReady ? 1.0 : 0.0
        loops: 1

        onStatusChanged: {
            root.ensureNotificationSound()
        }
    }

    // Login-safe retry loop. During a fresh Hyprland session Quickshell can
    // appear before PipeWire/default sink or QtMultimedia is fully ready.
    Timer {
        id: notificationSoundInitTimer

        interval: 500
        repeat: true
        running: !root.notificationSoundReady

        onTriggered: {
            root.ensureNotificationSound()
        }
    }

    // Let the silent warm-up run through the whole short WAV once. Afterwards
    // the exact same SoundEffect instance is armed at full volume.
    Timer {
        id: notificationSoundWarmupTimer

        interval: 850
        repeat: false

        onTriggered: {
            notificationPopSound.stop()

            root.notificationSoundWarmupRunning = false
            root.notificationSoundReady = true

            if (root.notificationSoundPending && !root.doNotDisturb) {
                root.notificationSoundPending = false

                Qt.callLater(() => {
                    notificationPopSound.stop()
                    notificationPopSound.play()
                })
            } else {
                root.notificationSoundPending = false
            }
        }
    }

    // Small delay used when SoundEffect entered Error during early login.
    // Reassigning the source makes QtMultimedia create the audio path again
    // after PipeWire/default sink is available.
    Timer {
        id: notificationSoundReloadTimer

        interval: 350
        repeat: false

        onTriggered: {
            root.notificationSoundReloadPending = false
            notificationPopSound.source = root.notificationSoundUrl
        }
    }

    function ensureNotificationSound() {
        if (root.notificationSoundReady || root.notificationSoundWarmupRunning)
            return

        // Do not initialize the multimedia path before PipeWire has a real
        // default output. This is the login race we specifically avoid.
        if (!root.sink)
            return

        if (notificationPopSound.status === SoundEffect.Error) {
            if (!root.notificationSoundReloadPending) {
                root.notificationSoundReloadPending = true
                notificationPopSound.source = ""
                notificationSoundReloadTimer.restart()
            }

            return
        }

        if (notificationPopSound.status !== SoundEffect.Ready)
            return

        root.notificationSoundWarmupRunning = true

        // volume is 0.0 until notificationSoundReady becomes true
        notificationPopSound.stop()
        notificationPopSound.play()
        notificationSoundWarmupTimer.restart()
    }

    function playNotificationSound() {
        if (root.doNotDisturb)
            return

        if (!root.notificationSoundReady) {
            // If the very first notification races the login initialization,
            // remember it instead of silently dropping the sound.
            root.notificationSoundPending = true
            root.ensureNotificationSound()
            return
        }

        notificationPopSound.stop()
        notificationPopSound.play()
    }

    readonly property bool hasUnreadNotifications: unreadNotificationCount > 0

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

    function isDndStatusNotification(notification) {
        if (!notification)
            return false

        return notification.appName === "Hypr-Lab"
            && (
                notification.summary === "Ne zavarjanak bekapcsolva."
                || notification.summary === "Ne zavarjanak kikapcsolva."
            )
    }

    // ============================================================
    // STATE
    // ============================================================

    property bool isHovered: hoverHandler.hovered

    property bool showVolume: false
    property bool showMediaEvent: false

    property bool showNotificationPreview: false
    property bool notificationCenterOpen: false

    // ============================================================
    // AUDIO
    // ============================================================

    property var sink: Pipewire.defaultAudioSink
    property var audio: sink ? sink.audio : null

    property real lastVolume:
        audio ? audio.volume : 0.0

    property bool isMuted:
        audio ? audio.muted : false

    property bool audioInitialized: false

    PwObjectTracker {
        objects: [root.sink]
    }

    // ============================================================
    // MEDIA
    // ============================================================

    property var activePlayer: null

    property bool mediaInitialized: false
    property bool wasPlaying: false
    property int lastTrackId: -1

    // ============================================================
    // NOTIFICATIONS
    // ============================================================

    property var latestNotification: null

    property int notificationCount:
        notificationServer
            .trackedNotifications
            .values
            .length

    property bool hasNotifications:
        notificationCount > 0

    // ============================================================
    // UI STATES
    // ============================================================

    property bool hoverMediaVisible:
        root.isHovered
        && root.activePlayer !== null
        && !root.notificationCenterOpen

    // Preview lejárta után hoverre továbbra is megmutatjuk.
    property bool hoverNotificationVisible:
        root.isHovered
        && root.hasNotifications
        && root.latestNotification !== null
        && !root.notificationCenterOpen

    property bool notificationCardVisible:
        root.showNotificationPreview
        || root.hoverNotificationVisible

    property bool expandedContent:
        root.isHovered
        || root.showNotificationPreview
        || root.notificationCenterOpen

    // ============================================================
    // LAYOUT CONSTANTS
    // ============================================================

    property int topPadding: 8
    property int bottomPadding: 14

    // Az eredeti TimeBlock 65px magas hover állapotban jól működött.
    property int timeSlotHeight:
        root.expandedContent ? 65 : 40

    property int mediaSlotHeight:
        (
            (
                root.hoverMediaVisible
                || root.showNotificationPreview
                || root.notificationCenterOpen
            )
            && root.activePlayer !== null
        )
        ? 36
        : 0

    property int previewSlotHeight:
        (
            root.notificationCardVisible
            && !root.notificationCenterOpen
        )
        ? 68
        : 0

    // Notification Center sizing:
    // each item is 68px high and ListView spacing is 6px.
    // Keep the whole list inside the island; once the panel reaches its
    // maximum height, the ListView itself remains scrollable.
    property int notificationItemHeight: 68
    property int notificationItemSpacing: 6
    property int notificationCenterMaxHeight: 460

    property int notificationListContentHeight:
        root.notificationCount > 0
        ? (
            root.notificationCount * root.notificationItemHeight
            + (root.notificationCount - 1) * root.notificationItemSpacing
        )
        : 0

    // 20px accounts for the separator + list top/bottom margins.
    // This guarantees that even the first notification card is fully visible,
    // while longer histories remain scrollable at the existing max height.
    property int centerSlotDesiredHeight:
        root.notificationCount === 0
        ? 66
        : 20 + root.notificationListContentHeight

    property int centerSlotAvailableHeight:
        Math.max(
            66,
            root.notificationCenterMaxHeight
            - root.topPadding
            - root.timeSlotHeight
            - root.mediaSlotHeight
            - root.bottomPadding
        )

    property int centerSlotHeight:
        root.notificationCenterOpen
        ? Math.min(
            root.centerSlotDesiredHeight,
            root.centerSlotAvailableHeight
        )
        : 0

    property int expandedTargetHeight:
        root.topPadding
        + root.timeSlotHeight
        + root.mediaSlotHeight
        + root.previewSlotHeight
        + root.centerSlotHeight
        + root.bottomPadding

    // ============================================================
    // SIZE
    // ============================================================

    property int targetWidth:
        root.notificationCenterOpen ? 360 :
        root.notificationCardVisible ? 360 :
        root.showVolume ? 260 :
        root.showMediaEvent ? 330 :
        root.isHovered ? 330 :
        240

    property int targetHeight:
        root.notificationCenterOpen
        ? root.expandedTargetHeight
        :
        root.showNotificationPreview
        ? root.expandedTargetHeight
        :
        root.showVolume
        ? 48
        :
        root.showMediaEvent
        ? 52
        :
        root.isHovered
        ? (
            (
                root.activePlayer !== null
                || root.hoverNotificationVisible
            )
            ? root.expandedTargetHeight
            : 65
        )
        :
        40

    property int currentWidth: targetWidth
    property int currentHeight: targetHeight

    width: currentWidth
    height: currentHeight

    // ============================================================
    // SPRING
    // ============================================================

    Behavior on currentWidth {
        SpringAnimation {
            spring: 3.5
            damping: 0.28
        }
    }

    Behavior on currentHeight {
        SpringAnimation {
            spring: 3.5
            damping: 0.28
        }
    }

    // ============================================================
    // NOTIFICATION SERVER
    // ============================================================

    NotificationServer {
        id: notificationServer

        // Advertise a richer freedesktop notification feature set.
        // Chromium/Vivaldi and other clients use GetCapabilities() when
        // deciding whether to hand notifications to the system daemon.
        bodySupported: true
        bodyMarkupSupported: true
        bodyImagesSupported: true
        imageSupported: true

        actionsSupported: true
        inlineReplySupported: true

        persistenceSupported: true

        // Compatibility capabilities also advertised by SwayNC.
        // Quickshell appends extraHints directly to GetCapabilities().
        extraHints: [
            "synchronous",
            "private-synchronous",
            "x-canonical-private-synchronous"
        ]

        keepOnReload: false

        onNotification: notification => {
            notification.tracked = true

            root.latestNotification = notification
            root.unreadNotificationCount += 1

            // DND alatt minden külső értesítés bekerül a history-ba,
            // de nem popupol. A saját DND ON/OFF visszajelzés mindig látszik.
            const dndStatus = root.isDndStatusNotification(notification)

            // One restrained Hypr-Lab pop for normal incoming notifications.
            // The sound is already loaded by SoundEffect, so playback does not
            // need to create a new process/PipeWire stream on every event.
            // DND status feedback stays silent, and DND suppresses sound.
            if (!root.doNotDisturb && !dndStatus) {
                root.playNotificationSound()
            }

            if (
                !root.notificationCenterOpen
                && (
                    !root.doNotDisturb
                    || dndStatus
                )
            ) {
                root.showNotificationPreview = true

                root.showVolume = false
                root.showMediaEvent = false

                volumeHideTimer.stop()
                mediaHideTimer.stop()

                notificationPreviewTimer.restart()
            }
        }
    }

    // ============================================================
    // NOTIFICATION CENTER OPEN / CLOSE
    // ============================================================

    function openNotificationCenter() {
        if (root.notificationCenterOpen)
            return

        root.notificationCenterOpen = true
        root.showNotificationPreview = false
        root.showVolume = false
        root.showMediaEvent = false

        // A history megnyitása elolvasásnak számít.
        root.unreadNotificationCount = 0

        notificationPreviewTimer.stop()
        volumeHideTimer.stop()
        mediaHideTimer.stop()

    }

    function closeNotificationCenter() {
        if (!root.notificationCenterOpen)
            return

        root.notificationCenterOpen = false
    }

    // ============================================================
    // IPC
    // ============================================================

    IpcHandler {
        target: "notifications"

        function toggle(): void {
            if (root.notificationCenterOpen)
                root.closeNotificationCenter()
            else
                root.openNotificationCenter()
        }

        function dnd(): void {
            root.toggleDnd()
        }

        function dndOn(): void {
            root.setDnd(true)
        }

        function dndOff(): void {
            root.setDnd(false)
        }
    }

    // ============================================================
    // NOTIFICATION PREVIEW TIMER
    // ============================================================

    Timer {
        id: notificationPreviewTimer

        interval: 5000
        repeat: false

        onTriggered: {
            root.showNotificationPreview = false
        }
    }

    // ============================================================
    // AUDIO
    // ============================================================

    onLastVolumeChanged: {
        if (!audioInitialized) {
            audioInitialized = true
            return
        }

        root.triggerVolumePop()
    }

    onIsMutedChanged: {
        if (!audioInitialized) {
            audioInitialized = true
            return
        }

        root.triggerVolumePop()
    }

    function triggerVolumePop() {
        root.notificationCenterOpen = false
        root.showNotificationPreview = false
        root.showMediaEvent = false

        notificationPreviewTimer.stop()
        mediaHideTimer.stop()

        root.showVolume = true
        volumeHideTimer.restart()
    }

    Timer {
        id: volumeHideTimer

        interval: 2000
        repeat: false

        onTriggered: {
            root.showVolume = false
        }
    }

    // ============================================================
    // MEDIA DISCOVERY
    // ============================================================

    Timer {
        id: mediaWatcher

        interval: 300
        running: true
        repeat: true

        onTriggered: {
            let players = Mpris.players.values
            let foundPlayer = null

            // ----------------------------------------------------
            // PLAYING
            // ----------------------------------------------------

            for (let i = 0; i < players.length; i++) {
                if (players[i].isPlaying) {
                    foundPlayer = players[i]
                    break
                }
            }

            // ----------------------------------------------------
            // KEEP CURRENT
            // ----------------------------------------------------

            if (!foundPlayer && root.activePlayer) {
                for (let i = 0; i < players.length; i++) {
                    if (
                        players[i]
                        === root.activePlayer
                    ) {
                        foundPlayer = players[i]
                        break
                    }
                }
            }

            // ----------------------------------------------------
            // CONTROLLABLE
            // ----------------------------------------------------

            if (!foundPlayer) {
                for (let i = 0; i < players.length; i++) {
                    if (players[i].canControl) {
                        foundPlayer = players[i]
                        break
                    }
                }
            }

            // ----------------------------------------------------
            // PLAYER CHANGE
            // ----------------------------------------------------

            if (
                foundPlayer
                !== root.activePlayer
            ) {
                root.activePlayer = foundPlayer

                if (foundPlayer) {
                    root.wasPlaying =
                        foundPlayer.isPlaying

                    root.lastTrackId =
                        foundPlayer.uniqueId

                    if (
                        root.mediaInitialized
                        && foundPlayer.isPlaying
                    ) {
                        root.triggerMediaPop()
                    }
                } else {
                    root.wasPlaying = false
                    root.lastTrackId = -1
                }

                root.mediaInitialized = true
                return
            }

            if (!foundPlayer)
                return

            // ----------------------------------------------------
            // PLAY / PAUSE
            // ----------------------------------------------------

            if (
                foundPlayer.isPlaying
                !== root.wasPlaying
            ) {
                root.wasPlaying =
                    foundPlayer.isPlaying

                if (root.mediaInitialized)
                    root.triggerMediaPop()
            }

            // ----------------------------------------------------
            // TRACK CHANGE
            // ----------------------------------------------------

            if (
                foundPlayer.uniqueId
                !== root.lastTrackId
            ) {
                root.lastTrackId =
                    foundPlayer.uniqueId

                if (root.mediaInitialized)
                    root.triggerMediaPop()
            }
        }
    }

    Connections {
        target: root.activePlayer

        function onTrackChanged() {
            if (!root.activePlayer)
                return

            root.lastTrackId =
                root.activePlayer.uniqueId

            if (root.mediaInitialized)
                root.triggerMediaPop()
        }
    }

    // ============================================================
    // MEDIA EVENT
    // ============================================================

    function triggerMediaPop() {
        if (
            root.notificationCenterOpen
            || root.showNotificationPreview
        ) {
            return
        }

        if (
            root.isHovered
            && root.activePlayer !== null
        ) {
            root.showMediaEvent = false
            mediaHideTimer.stop()
            return
        }

        root.showVolume = false
        root.showMediaEvent = true

        volumeHideTimer.stop()
        mediaHideTimer.restart()
    }

    Timer {
        id: mediaHideTimer

        interval: 2000
        repeat: false

        onTriggered: {
            root.showMediaEvent = false
        }
    }

    // ============================================================
    // DISMISS
    // ============================================================

    function dismissNotification(notification) {
        if (!notification)
            return

        if (
            root.latestNotification
            === notification
        ) {
            root.latestNotification = null
            root.showNotificationPreview = false
        }

        // X-re az adott értesítést olvasottnak tekintjük.
        if (root.unreadNotificationCount > 0)
            root.unreadNotificationCount -= 1

        notification.dismiss()
    }

    // ============================================================
    // CAPSULE
    // ============================================================

    Capsule {
        id: capsule

        anchors.centerIn: parent

        capsuleWidth: root.currentWidth
        capsuleHeight: root.currentHeight

        // A nyitott Notification Center panel legyen, ne óriás kapszula.
        // A többi CenterIsland állapot megtartja az eredeti pill formát.
        capsuleRadius:
            root.notificationCenterOpen
            ? 20
            : capsuleHeight / 2
    }

    Shadow {
        sourceItem: capsule
        z: -2
    }

    Glow {
        sourceItem: capsule
        z: -1
    }

    // ============================================================
    // EXPANDED CONTENT VIEWPORT
    //
    // A teljes tartalom a pill aktuális méretére van clipelve.
    // ============================================================

    Item {
        id: contentViewport

        anchors.centerIn: parent

        width: root.currentWidth
        height: root.currentHeight

        clip: true

        visible:
            root.expandedContent
            && !root.showVolume
            && !root.showMediaEvent

        z: 3

        Column {
            id: contentColumn

            // 16-16px belső margó.
            width:
                Math.max(
                    0,
                    root.currentWidth - 32
                )

            anchors.horizontalCenter:
                parent.horizontalCenter

            anchors.top:
                parent.top

            anchors.topMargin:
                root.topPadding

            spacing: 0

            // ====================================================
            // TIME SLOT
            // ====================================================

            Item {
                id: timeSlot

                width:
                    contentColumn.width

                height:
                    root.timeSlotHeight

                TimeBlock {
                    id: expandedTimeBlock

                    anchors.centerIn:
                        parent

                    expanded: true
                }
            }

            // ====================================================
            // MEDIA SLOT
            // ====================================================

            Item {
                id: mediaSlot

                width:
                    contentColumn.width

                height:
                    root.mediaSlotHeight

                clip: true

                MediaBlock {
                    anchors.horizontalCenter:
                        parent.horizontalCenter

                    anchors.verticalCenter:
                        parent.verticalCenter

                    active:
                        root.mediaSlotHeight > 0

                    player:
                        root.activePlayer

                    onInteraction: {
                        root.triggerMediaPop()
                    }
                }
            }

            // ====================================================
            // NOTIFICATION PREVIEW
            // ====================================================

            Item {
                id: previewSlot

                width:
                    contentColumn.width

                height:
                    root.previewSlotHeight

                clip: true

                NotificationItem {
                    id: notificationPreview

                    width:
                        Math.min(
                            parent.width,
                            320
                        )

                    anchors.centerIn:
                        parent

                    notification:
                        root.latestNotification

                    visible:
                        root.notificationCardVisible
                        && !root.notificationCenterOpen

                    onDismissRequested: {
                        root.dismissNotification(
                            root.latestNotification
                        )
                    }
                }
            }

            // ====================================================
            // NOTIFICATION CENTER
            // ====================================================

            Item {
                id: notificationCenterSlot

                width:
                    contentColumn.width

                height:
                    root.centerSlotHeight

                clip: true

                visible:
                    root.notificationCenterOpen

                Rectangle {
                    id: notificationSeparator

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top

                    anchors.topMargin: 6

                    height: 1

                    color: Qt.rgba(
                        1,
                        1,
                        1,
                        0.08
                    )
                }

                Text {
                    anchors.horizontalCenter:
                        parent.horizontalCenter

                    anchors.top:
                        notificationSeparator.bottom

                    anchors.topMargin: 20

                    visible:
                        root.notificationCenterOpen
                        && root.notificationCount === 0

                    text:
                        "Nincsenek értesítések"

                    color: Qt.rgba(
                        1,
                        1,
                        1,
                        0.42
                    )

                    font.family: "Inter"
                    font.pixelSize: 11
                }

                ListView {
                    id: notificationList

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: notificationSeparator.bottom
                    anchors.bottom: parent.bottom

                    anchors.topMargin: 7
                    anchors.leftMargin: 2
                    anchors.rightMargin: 2
                    anchors.bottomMargin: 4

                    visible:
                        root.notificationCenterOpen
                        && root.notificationCount > 0

                    spacing: root.notificationItemSpacing
                    clip: true

                    model:
                        notificationServer
                            .trackedNotifications

                    delegate: Item {
                        width:
                            notificationList.width

                        height: root.notificationItemHeight

                        NotificationItem {
                            width:
                                Math.min(
                                    parent.width,
                                    320
                                )

                            anchors.centerIn:
                                parent

                            notification:
                                modelData

                            onDismissRequested: {
                                root.dismissNotification(
                                    modelData
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    // ============================================================
    // IDLE CLOCK
    //
    // Nincs wrapper-width számolás -> nincs binding loop.
    // ============================================================

    TimeBlock {
        id: idleTimeBlock

        anchors.centerIn: parent

        // Az óra + Zz + olvasatlan pötty együtt marad optikailag középen.
        anchors.horizontalCenterOffset:
            root.doNotDisturb
            ? (root.hasUnreadNotifications ? -15 : -11)
            : (root.hasUnreadNotifications ? -5 : 0)

        expanded: false

        visible:
            !root.expandedContent
            && !root.showVolume
            && !root.showMediaEvent

        z: 5
    }

    // ============================================================
    // DND IDLE INDICATOR
    // ============================================================

    Text {
        id: dndIdleIndicator

        text: "Zz"
        color: "#37f5eb"

        font.family: "Inter"
        font.pixelSize: 10
        font.bold: true
        font.letterSpacing: 0.2

        visible:
            root.doNotDisturb
            && !root.expandedContent
            && !root.showVolume
            && !root.showMediaEvent

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: 43
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -1

        opacity: 0.82
        z: 6
    }

    // ============================================================
    // UNREAD NOTIFICATION DOT
    // ============================================================

    Rectangle {
        id: idleDot

        width: 7
        height: 7

        radius: width / 2

        color: "#ff4d5a"

        visible:
            root.hasUnreadNotifications
            && !root.expandedContent
            && !root.showVolume
            && !root.showMediaEvent

        anchors.horizontalCenter:
            parent.horizontalCenter

        // DND-nél a Zz mögé/jobbra kerül, különben marad az eredeti helyén.
        anchors.horizontalCenterOffset:
            root.doNotDisturb ? 67 : 40

        anchors.verticalCenter:
            parent.verticalCenter

        z: 6
    }

    // ============================================================
    // VOLUME EVENT
    // ============================================================

    VolumeBlock {
        anchors.centerIn: parent

        active:
            root.showVolume

        z: 7
    }

    // ============================================================
    // MEDIA EVENT
    //
    // Trackváltás / play-pause popup MEGMARAD.
    // ============================================================

    MediaBlock {
        id: eventMediaBlock

        anchors.centerIn: parent

        active:
            root.showMediaEvent
            && !root.showVolume
            && !root.notificationCenterOpen
            && !root.showNotificationPreview

        player:
            root.activePlayer

        z: 7

        onInteraction: {
            root.triggerMediaPop()
        }
    }

    // ============================================================
    // PASSIVE HOVER
    // ============================================================

    HoverHandler {
        id: hoverHandler
    }
}