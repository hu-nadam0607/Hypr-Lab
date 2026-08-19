import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import "controlcenter" as CC

Item {
    id: rightBarRoot

    property int barWidth: 1080
    property int barHeight: 36
    property color accentColor: "#68787D"
    property var notificationHost: null

    property bool capsLockActive: false
    property bool numLockActive: false
    property bool usbAvailable: false

    property bool volumePanelOpen: false
    property bool notificationPanelOpen: false
    property bool audioPanelFull: false
    property bool controlCenterPanelOpen: false
    property string controlCenterPage: "main" // main | settings | monitor
    readonly property bool anyPanelOpen: volumePanelOpen || notificationPanelOpen || controlCenterPanelOpen
    readonly property int compactPanelWidth: 360
    readonly property int compactPanelHeight: 118
    readonly property int fullPanelWidth: 520
    readonly property int fullPanelHeight: 430
    readonly property int controlPanelWidth: 500
    readonly property int controlMainHeight: 450
    readonly property int controlSettingsHeight: 450
    // Notification sheet starts at the same compact size as the volume sheet.
    // It grows one row at a time up to five visible notifications; additional
    // notifications stay available through the existing Flickable.
    readonly property int notificationPanelWidth: compactPanelWidth
    readonly property int notificationVisibleCount: notificationHost ? Math.min(notificationHost.notificationCount, 5) : 0
    readonly property int notificationPanelHeight: notificationVisibleCount <= 0
        ? compactPanelHeight
        : 76 + notificationVisibleCount * 78
    property int volumePanelWidth: controlCenterPanelOpen ? controlPanelWidth : (notificationPanelOpen ? notificationPanelWidth : (audioPanelFull ? fullPanelWidth : compactPanelWidth))
    property int volumePanelHeight: controlCenterPanelOpen ? (controlCenterPage === "main" ? controlMainHeight : controlSettingsHeight) : (notificationPanelOpen ? notificationPanelHeight : (audioPanelFull ? fullPanelHeight : compactPanelHeight))
    property real volumeReveal: anyPanelOpen ? 1.0 : 0.0

    property var sink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource
    readonly property var sinkAudio: sink ? sink.audio : null
    readonly property var sourceAudio: source ? source.audio : null
    readonly property real volumeLevel: sinkAudio ? sinkAudio.volume : 0.0
    readonly property bool muted: sinkAudio ? sinkAudio.muted : true

    readonly property var outputNodes: Pipewire.nodes.values.filter(node =>
        node && node.audio !== null && !node.isStream && node.isSink)
    readonly property var inputNodes: Pipewire.nodes.values.filter(node =>
        node && node.audio !== null && !node.isStream && !node.isSink)

    property bool lanOnline: false
    property string lanName: "Checking…"
    property string cpu: "--"
    property string ram: "--"
    property string uptime: "--"
    property var player: null
    property string themeMode: "system"

    function refreshLan() { lanRefresh.running = false; lanRefresh.running = true }
    function refreshStats() { statsProc.running = false; statsProc.running = true }
    function selectPlayer() {
        const list = Mpris.players.values
        let selected = null
        for (let i = 0; i < list.length; ++i) {
            if (list[i] && list[i].isPlaying) { selected = list[i]; break }
        }
        if (!selected && list.length > 0) selected = list[0]
        player = selected
    }
    function setThemeMode(mode) { themeMode = mode }
    function runCalculator() { Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/settings/calculator.sh"]) }
    function runScreenshotFull() { Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/hyprlab-scripts/screenshot-full.sh"]) }
    function runScreenshotArea() { Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/hyprlab-scripts/screenshot-area.sh"]) }

    signal wallpaperRequested()
    signal openPowerMenu()
    signal toggleUsbManager(var anchorItem)

    implicitWidth: barWidth
    readonly property real boundedControlReveal: controlCenterPanelOpen ? Math.max(0, Math.min(1.0, volumeReveal)) : Math.max(0, Math.min(1.08, volumeReveal))
    readonly property real boundedSurfaceHeight: controlCenterPanelOpen ? Math.min(volumePanelHeight, controlSettingsHeight) : volumePanelHeight

    implicitHeight: barHeight + Math.max(0, boundedSurfaceHeight * boundedControlReveal) + 8

    Behavior on volumeReveal {
        SpringAnimation {
            spring: 3.8
            damping: 0.26
            epsilon: 0.001
        }
    }

    Behavior on volumePanelWidth {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    Behavior on volumePanelHeight {
        SpringAnimation { spring: 4.2; damping: 0.32; epsilon: 0.1 }
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    function refreshLockStates() {
        if (!lockStateProcess.running)
            lockStateProcess.running = true
    }

    function setNodeVolume(audioObject, xPos, trackWidth) {
        if (!audioObject || trackWidth <= 0)
            return
        let value = Math.max(0, Math.min(1, xPos / trackWidth))
        audioObject.volume = value
        if (audioObject.muted)
            audioObject.muted = false
    }

    function selectOutput(node) {
        if (node) Pipewire.preferredDefaultAudioSink = node
    }

    function selectInput(node) {
        if (node) Pipewire.preferredDefaultAudioSource = node
    }

    function nodeName(node) {
        if (!node) return "Unknown device"
        if (node.description && node.description.length > 0) return node.description
        if (node.nickname && node.nickname.length > 0) return node.nickname
        return node.name || "Audio device"
    }

    function toggleAudioPanel() {
        notificationPanelOpen = false
        controlCenterPanelOpen = false
        if (!volumePanelOpen) audioPanelFull = false
        volumePanelOpen = !volumePanelOpen
    }

    function openFullAudioPanel() {
        notificationPanelOpen = false
        controlCenterPanelOpen = false
        volumePanelOpen = true
        audioPanelFull = true
    }

    function toggleNotificationPanel() {
        volumePanelOpen = false
        audioPanelFull = false
        controlCenterPanelOpen = false
        notificationPanelOpen = !notificationPanelOpen
        if (notificationPanelOpen && notificationHost) notificationHost.unreadNotificationCount = 0
    }

    function toggleControlCenterPanel() {
        const wasOpen = controlCenterPanelOpen
        volumePanelOpen = false
        audioPanelFull = false
        notificationPanelOpen = false
        controlCenterPage = "main"
        controlCenterPanelOpen = !wasOpen
        if (controlCenterPanelOpen) {
            refreshLan()
            refreshStats()
            selectPlayer()
        }
    }

    function openControlSettings() {
        volumePanelOpen = false
        audioPanelFull = false
        notificationPanelOpen = false
        controlCenterPanelOpen = true
        controlCenterPage = "settings"
    }

    function backToControlMain() {
        controlCenterPage = "main"
    }

    function closePanels() {
        notificationPanelOpen = false
        controlCenterPanelOpen = false
        audioPanelFull = false
        volumePanelOpen = false
    }

    IpcHandler {
        target: "topbarAudio"
        function toggle(): void { rightBarRoot.toggleAudioPanel() }
        function full(): void { rightBarRoot.openFullAudioPanel() }
        function close(): void { rightBarRoot.closePanels() }
    }

    IpcHandler {
        target: "controlcenter"
        function toggle(): void { rightBarRoot.toggleControlCenterPanel() }
        function open(): void { if (!rightBarRoot.controlCenterPanelOpen) rightBarRoot.toggleControlCenterPanel() }
        function close(): void { rightBarRoot.closePanels() }
        function main(): void { rightBarRoot.toggleControlCenterPanel() }
        function settings(): void { rightBarRoot.openControlSettings() }
        function audio(): void { rightBarRoot.openFullAudioPanel() }
    }

    ExpandableBarSurface {
        id: surface
        x: 0
        y: 0
        surfaceWidth: rightBarRoot.barWidth
        barHeight: rightBarRoot.barHeight
        extensionWidth: rightBarRoot.volumePanelWidth
        extensionHeight: rightBarRoot.boundedSurfaceHeight
        reveal: rightBarRoot.controlCenterPanelOpen
            ? Math.min(1.0, rightBarRoot.volumeReveal)
            : rightBarRoot.volumeReveal
        borderWidth: 2
        borderColor: Qt.rgba(rightBarRoot.accentColor.r, rightBarRoot.accentColor.g, rightBarRoot.accentColor.b, 0.86)
        unifiedTopBarMode: true
    }

    Connections {
        target: Mpris.players
        function onValuesChanged() { rightBarRoot.selectPlayer() }
    }

    Timer {
        interval: 1800
        repeat: true
        running: rightBarRoot.controlCenterPanelOpen
        triggeredOnStart: true
        onTriggered: { rightBarRoot.refreshStats(); rightBarRoot.selectPlayer() }
    }

    Process {
        id: lanRefresh
        command: ["sh", "-c", "dev=$(ip route show default 2>/dev/null | awk 'NR==1{print $5}'); if [ -z \"$dev\" ]; then echo '0|Offline'; exit; fi; state=$(cat /sys/class/net/$dev/operstate 2>/dev/null); if [ \"$state\" = up ]; then printf '1|%s · Online\\n' \"$dev\"; else printf '0|%s · %s\\n' \"$dev\" \"$state\"; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split("|")
                rightBarRoot.lanOnline = p[0] === "1"
                rightBarRoot.lanName = p.length > 1 ? p.slice(1).join("|") : "Ethernet"
            }
        }
    }

    Process {
        id: statsProc
        command: ["sh", "-c",
            "read _ u1 n1 s1 i1 w1 irq1 sirq1 st1 _ < /proc/stat; " +
            "t1=$((u1+n1+s1+i1+w1+irq1+sirq1+st1)); id1=$((i1+w1)); sleep 0.15; " +
            "read _ u2 n2 s2 i2 w2 irq2 sirq2 st2 _ < /proc/stat; " +
            "t2=$((u2+n2+s2+i2+w2+irq2+sirq2+st2)); id2=$((i2+w2)); " +
            "dt=$((t2-t1)); did=$((id2-id1)); if [ $dt -gt 0 ]; then cpu=$((100*(dt-did)/dt)); else cpu=0; fi; " +
            "ram=$(awk '/MemTotal:/ {t=$2} /MemAvailable:/ {a=$2} END {if(t>0) printf \"%.0f\",100*(t-a)/t; else print 0}' /proc/meminfo); " +
            "up=$(awk '{s=int($1); h=int(s/3600); m=int((s%3600)/60); if(h>0) printf \"%dh %02dm\",h,m; else printf \"%dm\",m}' /proc/uptime); " +
            "printf '%s|%s|%s\\n' \"$cpu\" \"$ram\" \"$up\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split("|")
                if (p.length >= 3) { rightBarRoot.cpu = p[0] + "%"; rightBarRoot.ram = p[1] + "%"; rightBarRoot.uptime = p[2] }
            }
        }
    }

    Process {
        id: lockStateProcess
        command: [
            "sh", "-c",
            "for k in capslock numlock; do " +
            "v=0; " +
            "for f in /sys/class/leds/input*::$k/brightness; do " +
            "if [ -r \"$f\" ]; then read x < \"$f\"; " +
            "if [ \"${x:-0}\" -gt 0 ] 2>/dev/null; then v=1; break; fi; fi; " +
            "done; printf '%s' \"$v\"; " +
            "[ \"$k\" != numlock ] && printf '|'; done; printf '\\n'"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("|")
                if (parts.length !== 2)
                    return
                rightBarRoot.capsLockActive = parts[0] === "1"
                rightBarRoot.numLockActive = parts[1] === "1"
            }
        }
    }

    Timer {
        interval: 250
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: rightBarRoot.refreshLockStates()
    }

    Row {
        id: contentRow
        anchors.right: parent.right
        anchors.rightMargin: 24
        y: 0
        height: rightBarRoot.barHeight
        spacing: 8
        z: 6

        BarActionButton {
            id: usbButton
            visible: rightBarRoot.usbAvailable
            icon: "󰕓"
            iconSize: 15
            accentColor: rightBarRoot.accentColor
            onClicked: rightBarRoot.toggleUsbManager(usbButton)
        }

        BarActionButton {
            id: audioButton
            icon: rightBarRoot.muted ? "󰖁" : "󰕾"
            iconSize: 15
            accentColor: rightBarRoot.accentColor
            onClicked: rightBarRoot.toggleAudioPanel()
        }

        BarActionButton {
            id: notificationButton
            icon: rightBarRoot.notificationHost && rightBarRoot.notificationHost.hasNotifications ? "󰂞" : "󰂚"
            iconSize: 15
            accentColor: rightBarRoot.accentColor
            forceAccent: rightBarRoot.notificationHost && rightBarRoot.notificationHost.hasNotifications
            onClicked: rightBarRoot.toggleNotificationPanel()
        }

        BarActionButton {
            id: controlCenterButton
            icon: "󰒓"
            iconSize: 15
            accentColor: rightBarRoot.accentColor
            onClicked: rightBarRoot.toggleControlCenterPanel()
        }

        Text {
            text: "/"
            color: Qt.rgba(rightBarRoot.accentColor.r, rightBarRoot.accentColor.g, rightBarRoot.accentColor.b, 0.46)
            font.family: "Inter"
            font.pixelSize: 15
            font.italic: true
            anchors.verticalCenter: parent.verticalCenter
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            scale: 0.82

            LockIndicator { symbol: "A"; active: rightBarRoot.capsLockActive; accentColor: rightBarRoot.accentColor }
            LockIndicator { symbol: "1"; active: rightBarRoot.numLockActive; accentColor: rightBarRoot.accentColor }
        }

        Text {
            text: "/"
            color: Qt.rgba(rightBarRoot.accentColor.r, rightBarRoot.accentColor.g, rightBarRoot.accentColor.b, 0.46)
            font.family: "Inter"
            font.pixelSize: 15
            font.italic: true
            anchors.verticalCenter: parent.verticalCenter
        }

        SysTray {
            id: sysTray
            anchors.verticalCenter: parent.verticalCenter
            scale: 0.78
            transformOrigin: Item.Right
            accentColor: rightBarRoot.accentColor
        }

        PowerButton {
            id: powerButton
            width: 24
            height: 24
            scale: 0.82
            anchors.verticalCenter: parent.verticalCenter
            onClicked: rightBarRoot.openPowerMenu()
        }
    }

    readonly property real extensionSlope: surface.slant / Math.max(1, rightBarRoot.barHeight)
    readonly property real extensionSideInset: 20
    readonly property real extensionSafeWidth:
        Math.max(120, rightBarRoot.volumePanelWidth - surface.slant * 2 - extensionSideInset * 2)

    // The expanded sheet has two PARALLEL slanted sides.  Its usable content
    // corridor therefore keeps a constant width, but its X origin moves left
    // continuously as Y increases.  All full-panel content uses this function.
    function extensionSafeLeftAt(relativeY) {
        const y = Math.max(0, relativeY)
        return rightBarRoot.barWidth
            - rightBarRoot.volumePanelWidth
            + surface.slant
            + rightBarRoot.extensionSideInset
            - rightBarRoot.extensionSlope * y
    }

    function extensionSafeRightAt(relativeY) {
        return extensionSafeLeftAt(relativeY) + rightBarRoot.extensionSafeWidth
    }

    function extensionCenterX(relativeY) {
        return extensionSafeLeftAt(relativeY) + rightBarRoot.extensionSafeWidth / 2
    }

    function extensionLeftFor(relativeY, itemWidth) {
        return extensionCenterX(relativeY) - itemWidth / 2
    }

    // Bounding rectangle that contains the complete slanted corridor.  This
    // lets Flickable keep rectangular clipping while every visible row still
    // follows the /______/ geometry independently.
    function scrollerEnvelopeLeft(panelHeight) {
        return extensionSafeLeftAt(panelHeight)
    }

    function scrollerEnvelopeWidth(panelHeight) {
        return rightBarRoot.extensionSafeWidth + rightBarRoot.extensionSlope * panelHeight
    }

    Item {
        id: volumeContent
        x: 0
        y: rightBarRoot.barHeight
        width: rightBarRoot.barWidth
        height: rightBarRoot.volumePanelHeight
        clip: true
        opacity: Math.max(0, Math.min(1, (rightBarRoot.volumeReveal - 0.12) / 0.78))
        visible: rightBarRoot.volumeReveal > 0.01
        z: 5

        transform: Translate {
            y: (1.0 - Math.min(1, rightBarRoot.volumeReveal)) * -14
        }

        // COMPACT VOLUME PANEL
        Item {
            anchors.fill: parent
            visible: !rightBarRoot.audioPanelFull && !rightBarRoot.notificationPanelOpen && !rightBarRoot.controlCenterPanelOpen

            Row {
                id: deviceRow
                y: 14
                width: rightBarRoot.extensionSafeWidth
                height: 22
                x: rightBarRoot.extensionLeftFor(y + height / 2, width)
                spacing: 10

                Text {
                    text: rightBarRoot.muted ? "󰖁" : "󰕾"
                    color: rightBarRoot.accentColor
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (rightBarRoot.sinkAudio)
                                rightBarRoot.sinkAudio.muted = !rightBarRoot.sinkAudio.muted
                        }
                    }
                }

                Text {
                    text: rightBarRoot.sink ? (rightBarRoot.sink.description || "Audio output") : "No output device"
                    color: Qt.rgba(1, 1, 1, 0.78)
                    font.family: "Inter"
                    font.italic: true
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    width: parent.width - 84
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: Math.round((rightBarRoot.muted ? 0 : rightBarRoot.volumeLevel) * 100) + "%"
                    color: "white"
                    font.family: "Inter"
                    font.italic: true
                    font.pixelSize: 11
                    font.bold: true
                    width: 38
                    horizontalAlignment: Text.AlignRight
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item {
                id: sliderSafeRow
                y: 48
                width: rightBarRoot.extensionSafeWidth
                height: 22
                x: rightBarRoot.extensionLeftFor(y + height / 2, width)

                Rectangle {
                    id: volumeTrack
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 5
                    radius: 2
                    color: Qt.rgba(1, 1, 1, 0.12)

                    Rectangle {
                        height: parent.height
                        radius: 2
                        width: Math.max(0, Math.min(parent.width, (rightBarRoot.muted ? 0 : rightBarRoot.volumeLevel) * parent.width))
                        color: rightBarRoot.accentColor
                        Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: function(mouse) { rightBarRoot.setNodeVolume(rightBarRoot.sinkAudio, mouse.x, width) }
                    onPositionChanged: function(mouse) {
                        if (pressed)
                            rightBarRoot.setNodeVolume(rightBarRoot.sinkAudio, mouse.x, width)
                    }
                }
            }

            Item {
                id: footerSafeRow
                y: 78
                width: rightBarRoot.extensionSafeWidth
                height: 24
                x: rightBarRoot.extensionLeftFor(y + height / 2, width)

                Text {
                    text: "VOLUME"
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    color: Qt.rgba(1, 1, 1, 0.40)
                    font.family: "Inter"
                    font.italic: true
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 1.2
                }

                Text {
                    id: audioSettingsLink
                    text: "Audio settings  ›"
                    anchors.right: parent.right
                    anchors.rightMargin: 1
                    anchors.verticalCenter: parent.verticalCenter
                    color: rightBarRoot.accentColor
                    font.family: "Inter"
                    font.italic: true
                    font.pixelSize: 10

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -5
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rightBarRoot.openFullAudioPanel()
                    }
                }
            }
        }

        // FULL AUDIO CONTROL PANEL — same glass sheet, same /______/ geometry.
        Item {
            anchors.fill: parent
            visible: rightBarRoot.audioPanelFull && !rightBarRoot.notificationPanelOpen && !rightBarRoot.controlCenterPanelOpen

            Item {
                id: fullHeader
                y: 12
                width: rightBarRoot.extensionSafeWidth
                height: 38
                x: rightBarRoot.extensionLeftFor(y + height / 2, width)

                Text {
                    id: backButton
                    text: "<  Vissza"
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    color: backMouse.containsMouse ? rightBarRoot.accentColor : Qt.rgba(1,1,1,0.66)
                    font.family: "Inter"
                    font.pixelSize: 10
                    font.bold: true
                    font.italic: true

                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rightBarRoot.audioPanelFull = false
                    }
                }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "AUDIO CONTROL"
                        color: "white"
                        font.family: "Inter"
                        font.pixelSize: 12
                        font.bold: true
                        font.italic: true
                        font.letterSpacing: 1.0
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "PipeWire · output / input"
                        color: Qt.rgba(1,1,1,0.38)
                        font.family: "Inter"
                        font.pixelSize: 8
                        font.italic: true
                    }
                }

                Text {
                    text: "×"
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    color: closeAudioMouse.containsMouse ? rightBarRoot.accentColor : Qt.rgba(1,1,1,0.60)
                    font.family: "Inter"
                    font.pixelSize: 17
                    font.bold: true
                    font.italic: true

                    MouseArea {
                        id: closeAudioMouse
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            rightBarRoot.audioPanelFull = false
                            rightBarRoot.volumePanelOpen = false
                        }
                    }
                }
            }

            // The content does not scroll on a perfectly vertical rail. As contentY grows,
            // the column drifts horizontally with the /______/ material, so the list feels
            // as if it rolls inside the slanted glass instead of inside a rectangular box.
            Flickable {
                id: audioScroller
                y: 58
                x: rightBarRoot.scrollerEnvelopeLeft(rightBarRoot.volumePanelHeight)
                width: rightBarRoot.scrollerEnvelopeWidth(rightBarRoot.volumePanelHeight)
                height: rightBarRoot.volumePanelHeight - 76
                contentWidth: width
                contentHeight: audioColumn.implicitHeight + 12
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: 1800

                Column {
                    id: audioColumn
                    width: audioScroller.width
                    spacing: 8

                    Text {
                        width: rightBarRoot.extensionSafeWidth
                        x: rightBarRoot.extensionSafeLeftAt(
                               audioScroller.y + y - audioScroller.contentY + height / 2
                           ) - audioScroller.x
                        text: "OUTPUT"
                        color: Qt.rgba(rightBarRoot.accentColor.r, rightBarRoot.accentColor.g, rightBarRoot.accentColor.b, 0.82)
                        font.family: "Inter"
                        font.pixelSize: 9
                        font.bold: true
                        font.italic: true
                        font.letterSpacing: 1.5
                    }

                    AudioStrip {
                        width: rightBarRoot.extensionSafeWidth
                        x: rightBarRoot.extensionSafeLeftAt(
                               audioScroller.y + y - audioScroller.contentY + height / 2
                           ) - audioScroller.x
                        icon: rightBarRoot.muted ? "󰖁" : "󰕾"
                        label: rightBarRoot.sink ? rightBarRoot.nodeName(rightBarRoot.sink) : "No output device"
                        value: rightBarRoot.volumeLevel
                        muted: rightBarRoot.muted
                        accentColor: rightBarRoot.accentColor
                        onValueRequested: function(value) {
                            if (!rightBarRoot.sinkAudio) return
                            rightBarRoot.sinkAudio.volume = value
                            if (rightBarRoot.sinkAudio.muted) rightBarRoot.sinkAudio.muted = false
                        }
                        onMuteRequested: {
                            if (rightBarRoot.sinkAudio) rightBarRoot.sinkAudio.muted = !rightBarRoot.sinkAudio.muted
                        }
                    }

                    Text {
                        width: rightBarRoot.extensionSafeWidth
                        x: rightBarRoot.extensionSafeLeftAt(
                               audioScroller.y + y - audioScroller.contentY + height / 2
                           ) - audioScroller.x
                        text: "OUTPUT DEVICES"
                        color: Qt.rgba(1,1,1,0.38)
                        font.family: "Inter"
                        font.pixelSize: 8
                        font.bold: true
                        font.italic: true
                        font.letterSpacing: 1.2
                    }

                    Repeater {
                        model: ScriptModel { values: rightBarRoot.outputNodes }
                        AudioDeviceStrip {
                            required property var modelData
                            width: rightBarRoot.extensionSafeWidth
                            x: rightBarRoot.extensionSafeLeftAt(
                                   audioScroller.y + y - audioScroller.contentY + height / 2
                               ) - audioScroller.x
                            node: modelData
                            outputDevice: true
                            active: modelData === Pipewire.defaultAudioSink
                            accentColor: rightBarRoot.accentColor
                            onSelectRequested: rightBarRoot.selectOutput(modelData)
                        }
                    }

                    Item { width: 1; height: 5 }

                    Text {
                        width: rightBarRoot.extensionSafeWidth
                        x: rightBarRoot.extensionSafeLeftAt(
                               audioScroller.y + y - audioScroller.contentY + height / 2
                           ) - audioScroller.x
                        text: "INPUT"
                        color: Qt.rgba(rightBarRoot.accentColor.r, rightBarRoot.accentColor.g, rightBarRoot.accentColor.b, 0.82)
                        font.family: "Inter"
                        font.pixelSize: 9
                        font.bold: true
                        font.italic: true
                        font.letterSpacing: 1.5
                    }

                    AudioStrip {
                        width: rightBarRoot.extensionSafeWidth
                        x: rightBarRoot.extensionSafeLeftAt(
                               audioScroller.y + y - audioScroller.contentY + height / 2
                           ) - audioScroller.x
                        icon: rightBarRoot.sourceAudio && rightBarRoot.sourceAudio.muted ? "󰍭" : "󰍬"
                        label: rightBarRoot.source ? rightBarRoot.nodeName(rightBarRoot.source) : "No input device"
                        value: rightBarRoot.sourceAudio ? rightBarRoot.sourceAudio.volume : 0.0
                        muted: rightBarRoot.sourceAudio ? rightBarRoot.sourceAudio.muted : true
                        accentColor: rightBarRoot.accentColor
                        onValueRequested: function(value) {
                            if (!rightBarRoot.sourceAudio) return
                            rightBarRoot.sourceAudio.volume = value
                            if (rightBarRoot.sourceAudio.muted) rightBarRoot.sourceAudio.muted = false
                        }
                        onMuteRequested: {
                            if (rightBarRoot.sourceAudio) rightBarRoot.sourceAudio.muted = !rightBarRoot.sourceAudio.muted
                        }
                    }

                    Text {
                        width: rightBarRoot.extensionSafeWidth
                        x: rightBarRoot.extensionSafeLeftAt(
                               audioScroller.y + y - audioScroller.contentY + height / 2
                           ) - audioScroller.x
                        text: "INPUT DEVICES"
                        color: Qt.rgba(1,1,1,0.38)
                        font.family: "Inter"
                        font.pixelSize: 8
                        font.bold: true
                        font.italic: true
                        font.letterSpacing: 1.2
                    }

                    Repeater {
                        model: ScriptModel { values: rightBarRoot.inputNodes }
                        AudioDeviceStrip {
                            required property var modelData
                            width: rightBarRoot.extensionSafeWidth
                            x: rightBarRoot.extensionSafeLeftAt(
                                   audioScroller.y + y - audioScroller.contentY + height / 2
                               ) - audioScroller.x
                            node: modelData
                            outputDevice: false
                            active: modelData === Pipewire.defaultAudioSource
                            accentColor: rightBarRoot.accentColor
                            onSelectRequested: rightBarRoot.selectInput(modelData)
                        }
                    }

                    Item { width: 1; height: 16 }
                }
            }
        }

        // CONTROL CENTER — lives inside the SAME RightBar material as volume/notifications.
        // The surface itself stretches from the bar; content rows follow the slanted corridor.
        Item {
            anchors.fill: parent
            visible: rightBarRoot.controlCenterPanelOpen

            Item {
                anchors.fill: parent
                visible: rightBarRoot.controlCenterPage === "main"

                Item {
                    id: ccHeader
                    y: 12
                    width: rightBarRoot.extensionSafeWidth
                    height: 34
                    x: rightBarRoot.extensionLeftFor(y + height / 2, width)

                    Column {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1
                        Text { text: "CONTROL CENTER"; color: "white"; font.family: "Inter"; font.pixelSize: 11; font.bold: true; font.italic: true; font.letterSpacing: 1.0 }
                        Text { text: "Hypr-Lab · system control"; color: Qt.rgba(1,1,1,0.38); font.family: "Inter"; font.pixelSize: 8; font.italic: true }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "×"
                        color: ccCloseMouse.containsMouse ? rightBarRoot.accentColor : Qt.rgba(1,1,1,0.60)
                        font.family: "Inter"; font.pixelSize: 17; font.bold: true
                        MouseArea { id: ccCloseMouse; anchors.fill: parent; anchors.margins: -8; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: rightBarRoot.closePanels() }
                    }
                }

                // Internet / Settings / DND — one centered row that follows the panel geometry.
                Row {
                    id: ccQuickRow
                    y: 58
                    width: rightBarRoot.extensionSafeWidth
                    height: 42
                    x: rightBarRoot.extensionLeftFor(y + height / 2, width)
                    spacing: 12

                    Repeater {
                        model: [
                            { icon: rightBarRoot.lanOnline ? "󰈀" : "󰈂", label: rightBarRoot.lanName, action: "none", active: rightBarRoot.lanOnline },
                            { icon: "󰒓", label: "Settings", action: "settings", active: false },
                            { icon: rightBarRoot.notificationHost && rightBarRoot.notificationHost.doNotDisturb ? "󰂛" : "󰂚", label: "DND", action: "dnd", active: rightBarRoot.notificationHost ? rightBarRoot.notificationHost.doNotDisturb : false }
                        ]

                        Item {
                            required property var modelData
                            width: (ccQuickRow.width - ccQuickRow.spacing * 2) / 3
                            height: ccQuickRow.height

                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: modelData.icon; color: modelData.active ? rightBarRoot.accentColor : Qt.rgba(1,1,1,0.68); font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14 }
                                Text {
                                    text: modelData.label
                                    color: Qt.rgba(1,1,1,0.74)
                                    font.family: "Inter"
                                    font.pixelSize: 9
                                    font.bold: true
                                    font.italic: true
                                }
                            }
                            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: modelData.active ? Qt.rgba(rightBarRoot.accentColor.r,rightBarRoot.accentColor.g,rightBarRoot.accentColor.b,0.72) : Qt.rgba(1,1,1,0.08) }
                            MouseArea {
                                anchors.fill: parent
                                enabled: modelData.action !== "none"
                                hoverEnabled: true
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (modelData.action === "settings") rightBarRoot.openControlSettings()
                                    else if (modelData.action === "dnd" && rightBarRoot.notificationHost) rightBarRoot.notificationHost.toggleDnd()
                                }
                            }
                        }
                    }
                }

                Text { y: 116; width: rightBarRoot.extensionSafeWidth; height: 14; x: rightBarRoot.extensionLeftFor(y + height/2,width); text: "THEME"; color: Qt.rgba(rightBarRoot.accentColor.r,rightBarRoot.accentColor.g,rightBarRoot.accentColor.b,0.80); font.family: "Inter"; font.pixelSize: 8; font.bold: true; font.italic: true; font.letterSpacing: 1.3 }

                Row {
                    id: themeRow
                    y: 136
                    width: rightBarRoot.extensionSafeWidth
                    height: 38
                    x: rightBarRoot.extensionLeftFor(y + height / 2, width)
                    spacing: 10
                    Repeater {
                        model: [ { label:"Világos", mode:"light", icon:"󰖨" }, { label:"Sötét", mode:"dark", icon:"󰖔" }, { label:"Rendszer", mode:"system", icon:"󰍹" } ]
                        Item {
                            required property var modelData
                            width: (themeRow.width - themeRow.spacing * 2) / 3
                            height: themeRow.height
                            Row { anchors.centerIn: parent; spacing: 6
                                Text { text: modelData.icon; color: rightBarRoot.themeMode === modelData.mode ? rightBarRoot.accentColor : Qt.rgba(1,1,1,0.58); font.family:"JetBrainsMono Nerd Font"; font.pixelSize:13 }
                                Text { text:modelData.label; color: rightBarRoot.themeMode === modelData.mode ? "white" : Qt.rgba(1,1,1,0.62); font.family:"Inter"; font.pixelSize:9; font.bold:true; font.italic:true }
                            }
                            Rectangle { anchors.left:parent.left; anchors.right:parent.right; anchors.bottom:parent.bottom; height:1; color:rightBarRoot.themeMode === modelData.mode ? rightBarRoot.accentColor : Qt.rgba(1,1,1,0.07) }
                            MouseArea { anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor; onClicked:rightBarRoot.setThemeMode(modelData.mode) }
                        }
                    }
                }

                Text { y: 188; width: rightBarRoot.extensionSafeWidth; height: 14; x: rightBarRoot.extensionLeftFor(y + height/2,width); text: "TOOLS"; color: Qt.rgba(rightBarRoot.accentColor.r,rightBarRoot.accentColor.g,rightBarRoot.accentColor.b,0.80); font.family:"Inter"; font.pixelSize:8; font.bold:true; font.italic:true; font.letterSpacing:1.3 }

                Row {
                    id: toolsRow
                    y: 208
                    width: rightBarRoot.extensionSafeWidth
                    height: 42
                    x: rightBarRoot.extensionLeftFor(y + height/2,width)
                    spacing: 12

                    Item {
                        width:(toolsRow.width-toolsRow.spacing*2)/3; height:parent.height
                        Row {
                            anchors.centerIn: parent
                            spacing: 7

                            Text {
                                text: "󰃬"
                                color: rightBarRoot.accentColor
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                            }

                            Text {
                                text: "Számológép"
                                color: Qt.rgba(1,1,1,0.72)
                                font.family: "Inter"
                                font.pixelSize: 9
                                font.bold: true
                                font.italic: true
                            }
                        }
                        Rectangle { anchors.left:parent.left; anchors.right:parent.right; anchors.bottom:parent.bottom; height:1; color:Qt.rgba(1,1,1,0.08) }
                        MouseArea { anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor; onClicked:rightBarRoot.runCalculator() }
                    }
                    Item {
                        width:(toolsRow.width-toolsRow.spacing*2)/3; height:parent.height
                        Row {
                            anchors.centerIn: parent
                            spacing: 7

                            Text {
                                text: "󰹑"
                                color: rightBarRoot.accentColor
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                            }

                            Text {
                                text: "Teljes kép"
                                color: Qt.rgba(1,1,1,0.72)
                                font.family: "Inter"
                                font.pixelSize: 9
                                font.bold: true
                                font.italic: true
                            }
                        }
                        Rectangle { anchors.left:parent.left; anchors.right:parent.right; anchors.bottom:parent.bottom; height:1; color:Qt.rgba(1,1,1,0.08) }
                        MouseArea { anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor; onClicked:{ rightBarRoot.closePanels(); rightBarRoot.runScreenshotFull() } }
                    }
                    Item {
                        width:(toolsRow.width-toolsRow.spacing*2)/3; height:parent.height
                        Row {
                            anchors.centerIn: parent
                            spacing: 7

                            Text {
                                text: "󰩬"
                                color: rightBarRoot.accentColor
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                            }

                            Text {
                                text: "Terület"
                                color: Qt.rgba(1,1,1,0.72)
                                font.family: "Inter"
                                font.pixelSize: 9
                                font.bold: true
                                font.italic: true
                            }
                        }
                        Rectangle { anchors.left:parent.left; anchors.right:parent.right; anchors.bottom:parent.bottom; height:1; color:Qt.rgba(1,1,1,0.08) }
                        MouseArea { anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor; onClicked:{ rightBarRoot.closePanels(); rightBarRoot.runScreenshotArea() } }
                    }
                }

                Row {
                    id: actionRow
                    y: 264
                    width: rightBarRoot.extensionSafeWidth
                    height: 42
                    x: rightBarRoot.extensionLeftFor(y + height/2,width)
                    spacing: 12

                    Repeater {
                        model: [ {icon:"󰸉",label:"Wallpaper",act:"wall"}, {icon:"󰕾",label:"Audio",act:"audio"}, {icon:"󰐥",label:"Power",act:"power"} ]
                        Item {
                            required property var modelData
                            width:(actionRow.width-actionRow.spacing*2)/3; height:actionRow.height
                            Row {
                                anchors.centerIn: parent
                                spacing: 7

                                Text {
                                    text: modelData.icon
                                    color: rightBarRoot.accentColor
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 14
                                }

                                Text {
                                    text: modelData.label
                                    color: Qt.rgba(1,1,1,0.72)
                                    font.family: "Inter"
                                    font.pixelSize: 9
                                    font.bold: true
                                    font.italic: true
                                }
                            }
                            Rectangle { anchors.left:parent.left; anchors.right:parent.right; anchors.bottom:parent.bottom; height:1; color:Qt.rgba(1,1,1,0.08) }
                            MouseArea { anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor; onClicked:{
                                if(modelData.act==="wall") { rightBarRoot.closePanels(); rightBarRoot.wallpaperRequested() }
                                else if(modelData.act==="audio") rightBarRoot.openFullAudioPanel()
                                else if(modelData.act==="power") { rightBarRoot.closePanels(); rightBarRoot.openPowerMenu() }
                            } }
                        }
                    }
                }

                Text { y: 320; width: rightBarRoot.extensionSafeWidth; height: 14; x: rightBarRoot.extensionLeftFor(y + height/2,width); text: "MEDIA"; color: Qt.rgba(rightBarRoot.accentColor.r,rightBarRoot.accentColor.g,rightBarRoot.accentColor.b,0.80); font.family:"Inter"; font.pixelSize:8; font.bold:true; font.italic:true; font.letterSpacing:1.3 }

                Item {
                    id: ccMedia
                    y: 340
                    width: rightBarRoot.extensionSafeWidth
                    height: 78
                    x: rightBarRoot.extensionLeftFor(y + height/2,width)

                    Text { anchors.left:parent.left; anchors.right:ccMediaControls.left; anchors.rightMargin:10; anchors.top:parent.top; text:rightBarRoot.player?((rightBarRoot.player.trackTitle||"Unknown")+" · "+(rightBarRoot.player.trackArtist||"")):"No active player"; color:Qt.rgba(1,1,1,0.74); font.family:"Inter"; font.pixelSize:9; font.bold:true; font.italic:true; elide:Text.ElideRight }
                    Row { id:ccMediaControls; anchors.right:parent.right; anchors.top:parent.top; spacing:10
                        Text { text:"󰒮"; color:Qt.rgba(1,1,1,0.62); font.family:"JetBrainsMono Nerd Font"; font.pixelSize:12; MouseArea{anchors.fill:parent;anchors.margins:-5;enabled:!!rightBarRoot.player;cursorShape:Qt.PointingHandCursor;onClicked:if(rightBarRoot.player)rightBarRoot.player.previous()} }
                        Text { text:rightBarRoot.player&&rightBarRoot.player.isPlaying?"󰏤":"󰐊"; color:rightBarRoot.accentColor; font.family:"JetBrainsMono Nerd Font"; font.pixelSize:12; MouseArea{anchors.fill:parent;anchors.margins:-5;enabled:!!rightBarRoot.player;cursorShape:Qt.PointingHandCursor;onClicked:if(rightBarRoot.player)rightBarRoot.player.togglePlaying()} }
                        Text { text:"󰒭"; color:Qt.rgba(1,1,1,0.62); font.family:"JetBrainsMono Nerd Font"; font.pixelSize:12; MouseArea{anchors.fill:parent;anchors.margins:-5;enabled:!!rightBarRoot.player;cursorShape:Qt.PointingHandCursor;onClicked:if(rightBarRoot.player)rightBarRoot.player.next()} }
                    }
                    CC.CavaVisualizer {
                        id: ccCava
                        width: rightBarRoot.extensionSafeWidth
                        height: 32
                        anchors.bottom: parent.bottom
                        // Center the visualizer on the slanted content corridor at
                        // the visualizer's own Y position, not at ccMedia's midpoint.
                        // This keeps CAVA aligned with the rest of the Control Center.
                        x: rightBarRoot.extensionLeftFor(
                               ccMedia.y + y + height / 2,
                               width
                           ) - ccMedia.x
                        active: rightBarRoot.player !== null && rightBarRoot.player.isPlaying
                        barCount: 24
                        barSpacing: 3
                        barColor: Qt.rgba(rightBarRoot.accentColor.r,
                                          rightBarRoot.accentColor.g,
                                          rightBarRoot.accentColor.b, 0.72)
                    }
                }

                Text { y: 430; width: rightBarRoot.extensionSafeWidth; height: 18; x: rightBarRoot.extensionLeftFor(y+height/2,width); text:"CPU "+rightBarRoot.cpu+"   /   RAM "+rightBarRoot.ram+"   /   UP "+rightBarRoot.uptime; color:Qt.rgba(1,1,1,0.43); font.family:"Inter"; font.pixelSize:8; font.bold:true; font.italic:true }
            }

            // SETTINGS — same slanted panel, flat rows, wallpaper-adaptive accents.
            Item {
                anchors.fill: parent
                visible: rightBarRoot.controlCenterPage === "settings"

                Item {
                    y: 12
                    width: rightBarRoot.extensionSafeWidth
                    height: 34
                    x: rightBarRoot.extensionLeftFor(y + height/2,width)
                    Text { anchors.left:parent.left; anchors.verticalCenter:parent.verticalCenter; text:"‹ Vissza"; color:settingsBack.containsMouse?rightBarRoot.accentColor:Qt.rgba(1,1,1,0.68); font.family:"Inter"; font.pixelSize:10; font.bold:true; font.italic:true; MouseArea{id:settingsBack;anchors.fill:parent;anchors.margins:-7;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:rightBarRoot.backToControlMain()} }
                    Column {
                        anchors.centerIn: parent
                        spacing: 0

                        Text {
                            text: "SETTINGS"
                            color: "white"
                            font.family: "Inter"
                            font.pixelSize: 11
                            font.bold: true
                            font.italic: true
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            text: "Hyprland + Hypr-Lab"
                            color: Qt.rgba(1,1,1,0.38)
                            font.family: "Inter"
                            font.pixelSize: 8
                            font.italic: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                    Text { anchors.right:parent.right; anchors.verticalCenter:parent.verticalCenter; text:"×"; color:settingsClose.containsMouse?rightBarRoot.accentColor:Qt.rgba(1,1,1,0.60); font.family:"Inter"; font.pixelSize:17; font.bold:true; MouseArea{id:settingsClose;anchors.fill:parent;anchors.margins:-8;hoverEnabled:true;cursorShape:Qt.PointingHandCursor;onClicked:rightBarRoot.closePanels()} }
                }

                CC.SettingsPage {
                    id: slantedSettings
                    y: 56
                    x: rightBarRoot.scrollerEnvelopeLeft(rightBarRoot.volumePanelHeight)
                    width: rightBarRoot.scrollerEnvelopeWidth(rightBarRoot.volumePanelHeight)
                    height: rightBarRoot.volumePanelHeight - 70
                    accentColor: rightBarRoot.accentColor
                    slope: rightBarRoot.extensionSlope
                    corridorWidth: rightBarRoot.extensionSafeWidth
                    corridorTopLeft: rightBarRoot.extensionSafeLeftAt(y) - x
                    showHeader: false
                    onBackRequested: rightBarRoot.backToControlMain()
                    onCloseRequested: rightBarRoot.closePanels()
                    onMonitorRequested: rightBarRoot.controlCenterPage = "monitor"
                }
            }

            Item {
                anchors.fill: parent
                visible: rightBarRoot.controlCenterPage === "monitor"

                CC.MonitorSettingsPage {
                    id: slantedMonitorSettings
                    y: 8
                    x: rightBarRoot.scrollerEnvelopeLeft(rightBarRoot.volumePanelHeight)
                    width: rightBarRoot.scrollerEnvelopeWidth(rightBarRoot.volumePanelHeight)
                    height: rightBarRoot.volumePanelHeight - 18
                    accentColor: rightBarRoot.accentColor
                    slope: rightBarRoot.extensionSlope
                    corridorWidth: rightBarRoot.extensionSafeWidth
                    corridorTopLeft: rightBarRoot.extensionSafeLeftAt(y) - x
                    onBackRequested: rightBarRoot.controlCenterPage = "settings"
                    onCloseRequested: rightBarRoot.closePanels()
                }
            }

        }

        // NOTIFICATION PANEL — same elastic sheet as audio, driven by the bell.
        Item {
            anchors.fill: parent
            visible: rightBarRoot.notificationPanelOpen

            Item {
                id: notificationHeader
                y: 14
                width: rightBarRoot.extensionSafeWidth
                height: 34
                x: rightBarRoot.extensionLeftFor(y + height / 2, width)

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "ÉRTESÍTÉSEK"
                    color: "white"
                    font.family: "Inter"
                    font.pixelSize: 11
                    font.bold: true
                    font.italic: true
                    font.letterSpacing: 1.0
                }

                Text {
                    anchors.right: closeNotif.left
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Összes értesítés törlése"
                    color: clearAllMouse.containsMouse ? rightBarRoot.accentColor : Qt.rgba(1,1,1,0.55)
                    font.family: "Inter"
                    font.pixelSize: 9
                    font.italic: true
                    MouseArea {
                        id: clearAllMouse
                        anchors.fill: parent
                        anchors.margins: -7
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (rightBarRoot.notificationHost) rightBarRoot.notificationHost.clearAllNotifications()
                    }
                }

                Text {
                    id: closeNotif
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "×"
                    color: closeNotifMouse.containsMouse ? rightBarRoot.accentColor : Qt.rgba(1,1,1,0.62)
                    font.family: "Inter"
                    font.pixelSize: 17
                    font.bold: true
                    MouseArea { id: closeNotifMouse; anchors.fill: parent; anchors.margins: -8; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: rightBarRoot.notificationPanelOpen = false }
                }
            }

            Flickable {
                id: notificationScroller
                y: 56
                x: rightBarRoot.scrollerEnvelopeLeft(rightBarRoot.volumePanelHeight)
                width: rightBarRoot.scrollerEnvelopeWidth(rightBarRoot.volumePanelHeight)
                height: rightBarRoot.volumePanelHeight - 74
                contentWidth: width
                contentHeight: notificationColumn.implicitHeight + 12
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: 1900

                Column {
                    id: notificationColumn
                    width: notificationScroller.width
                    spacing: 8

                    Text {
                        visible: !rightBarRoot.notificationHost || !rightBarRoot.notificationHost.hasNotifications
                        width: rightBarRoot.extensionSafeWidth
                        x: rightBarRoot.extensionSafeLeftAt(
                               notificationScroller.y + y - notificationScroller.contentY + height / 2
                           ) - notificationScroller.x
                        text: "Nincs értesítés"
                        color: Qt.rgba(1,1,1,0.40)
                        font.family: "Inter"
                        font.pixelSize: 10
                        font.italic: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Repeater {
                        model: rightBarRoot.notificationHost ? rightBarRoot.notificationHost.notificationModel : null

                        NotificationItem {
                            required property var modelData
                            width: rightBarRoot.extensionSafeWidth
                            x: rightBarRoot.extensionSafeLeftAt(
                                   notificationScroller.y + y - notificationScroller.contentY + height / 2
                               ) - notificationScroller.x
                            notification: modelData
                            accentColor: rightBarRoot.accentColor
                            onDismissRequested: if (modelData) modelData.dismiss()
                        }
                    }
                }
            }
        }

    }
}
