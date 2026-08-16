import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    property var notificationHost: null

    signal wallpaperRequested()
    signal powerRequested()

    property bool isOpen: false
    property bool windowVisible: false
    property string currentPage: "main"
    property real glassProgress: 0.0
    property real bodyProgress: 0.0
    property real borderProgress: 0.0
    property real contentProgress: 0.0
    property string pendingAction: ""

    property bool lanOnline: false
    property string lanName: "Checking…"

    readonly property int cardWidth: 448
    readonly property int collapsedHeight: 42
    readonly property int mainHeight: Math.ceil(mainContent.implicitHeight + 32)
    readonly property int audioHeight: 560
    readonly property int settingsHeight: 620
    readonly property int monitorHeight: 620
    readonly property int openTargetHeight:
        root.currentPage === "audio" ? root.audioHeight
        : root.currentPage === "settings" ? root.settingsHeight
        : root.currentPage === "monitor" ? root.monitorHeight
        : root.mainHeight
    readonly property int animatedHeight: Math.max(root.collapsedHeight,
        Math.round(root.collapsedHeight + (root.openTargetHeight - root.collapsedHeight) * root.bodyProgress))

    function prepareOpen(page) {
        closeBodyDelay.stop()
        closeGlassDelay.stop()
        hideWindowDelay.stop()
        actionDelay.stop()

        currentPage = page
        windowVisible = true
        isOpen = true
        focusDelay.restart()
        glassProgress = 1.0
        bodyProgress = 0.0
        contentProgress = 0.0
        borderProgress = 0.0

        lanRefresh.running = false
        lanRefresh.running = true
        bodyOpenDelay.restart()
        contentOpenDelay.restart()
        borderOpenDelay.restart()
    }

    function open() {
        if (isOpen) {
            currentPage = "main"
            focusDelay.restart()
            return
        }
        prepareOpen("main")
    }

    function openAudio() {
        if (isOpen) {
            currentPage = "audio"
            focusDelay.restart()
            return
        }
        prepareOpen("audio")
    }

    function openSettings() {
        if (isOpen) {
            currentPage = "settings"
            focusDelay.restart()
            return
        }
        prepareOpen("settings")
    }

    function openMonitor() {
        if (isOpen) {
            currentPage = "monitor"
            focusDelay.restart()
            return
        }
        prepareOpen("monitor")
    }

    function close() {
        if (!windowVisible) return

        isOpen = false
        bodyOpenDelay.stop()
        contentOpenDelay.stop()
        borderOpenDelay.stop()

        borderProgress = 0.0
        contentProgress = 0.0
        closeBodyDelay.restart()
        closeGlassDelay.restart()
        hideWindowDelay.restart()
    }

    function toggle() {
        if (isOpen) close()
        else open()
    }

    function toggleMain() {
        if (isOpen && currentPage === "main") close()
        else open()
    }

    function toggleAudio() {
        if (isOpen && currentPage === "audio") close()
        else openAudio()
    }

    function toggleDnd() {
        if (notificationHost)
            notificationHost.toggleDnd()
    }

    function runAfterClose(action) {
        pendingAction = action
        close()
        actionDelay.restart()
    }

    IpcHandler {
        target: "controlcenter"
        function toggle(): void { root.toggle() }
        function open(): void { root.open() }
        function close(): void { root.close() }
        function main(): void { root.toggleMain() }
        function audio(): void { root.toggleAudio() }
        function settings(): void { root.openSettings() }
        function monitor(): void { root.openMonitor() }
    }

    Timer {
        id: focusDelay
        interval: 1
        onTriggered: {
            if (root.isOpen)
                keyCatcher.forceActiveFocus()
        }
    }

    Timer { id: bodyOpenDelay; interval: 12; onTriggered: root.bodyProgress = 1.0 }
    Timer { id: contentOpenDelay; interval: 38; onTriggered: root.contentProgress = 1.0 }
    Timer { id: borderOpenDelay; interval: 142; onTriggered: root.borderProgress = 1.0 }
    Timer { id: closeBodyDelay; interval: 65; onTriggered: root.bodyProgress = 0.0 }
    Timer { id: closeGlassDelay; interval: 155; onTriggered: root.glassProgress = 0.0 }
    Timer {
        id: hideWindowDelay
        interval: 250
        onTriggered: {
            if (!root.isOpen) {
                root.windowVisible = false
                root.currentPage = "main"
            }
        }
    }

    Timer {
        id: actionDelay
        interval: 265
        onTriggered: {
            const action = root.pendingAction
            root.pendingAction = ""
            if (action === "wallpaper") root.wallpaperRequested()
            else if (action === "power") Quickshell.execDetached(["qs", "ipc", "call", "powermenu", "toggle"])
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.isOpen
        triggeredOnStart: true
        onTriggered: {
            if (!lanRefresh.running)
                lanRefresh.running = true
        }
    }

    Behavior on glassProgress { NumberAnimation { duration: 85; easing.type: Easing.OutCubic } }
    Behavior on bodyProgress { NumberAnimation { duration: 135; easing.type: Easing.OutCubic } }
    Behavior on contentProgress { NumberAnimation { duration: 95; easing.type: Easing.OutCubic } }
    Behavior on borderProgress { NumberAnimation { duration: 55; easing.type: Easing.InOutCubic } }

    Process {
        id: lanRefresh
        command: [
            "sh", "-c",
            "dev=$(ip route show default 2>/dev/null | awk 'NR==1{print $5}'); " +
            "if [ -z \"$dev\" ]; then echo '0|Offline'; exit; fi; " +
            "state=$(cat /sys/class/net/$dev/operstate 2>/dev/null); " +
            "if [ \"$state\" = up ]; then printf '1|%s · Online\\n' \"$dev\"; else printf '0|%s · %s\\n' \"$dev\" \"$state\"; fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("|")
                root.lanOnline = parts[0] === "1"
                root.lanName = parts.length > 1 ? parts.slice(1).join("|") : "Ethernet"
            }
        }
    }

    PanelWindow {
        id: panel
        visible: root.windowVisible

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        focusable: true
        aboveWindows: true

        WlrLayershell.namespace: "hypr-lab-control-center"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        Item {
            id: keyCatcher
            anchors.fill: parent
            focus: root.isOpen
            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape && root.isOpen) {
                    root.close()
                    event.accepted = true
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: root.close()
        }

        Rectangle {
            id: glassCard
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.top: parent.top
            anchors.topMargin: 49
            width: root.cardWidth
            height: root.animatedHeight
            radius: 20
            color: Qt.rgba(15/255, 20/255, 28/255, 0.82)
            border.width: 0
            border.color: "transparent"
            opacity: root.glassProgress
            clip: true

            Behavior on height {
                NumberAnimation { duration: 170; easing.type: Easing.OutCubic }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                propagateComposedEvents: false
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: 18
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(255/255,255/255,255/255,0.035)
            }

            Item {
                id: mainPage
                anchors.fill: parent
                anchors.margins: 16
                opacity: root.currentPage === "main" ? root.contentProgress : 0.0
                x: root.currentPage === "main" ? 0 : -26
                enabled: root.currentPage === "main" && root.isOpen

                Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                Column {
                    id: mainContent
                    width: parent.width
                    spacing: 10

                    ControlHeader {
                        width: parent.width
                        onCloseRequested: root.close()
                    }

                    Row {
                        width: parent.width
                        spacing: 8

                        QuickToggle {
                            width: (parent.width - 16) / 3
                            title: "Ethernet"
                            subtitle: root.lanName
                            icon: root.lanOnline ? "󰈀" : "󰈂"
                            active: root.lanOnline
                            available: true
                            interactive: false
                        }

                        QuickToggle {
                            width: (parent.width - 16) / 3
                            title: "Settings"
                            subtitle: "Hypr-Lab"
                            icon: "󰒓"
                            active: false
                            available: true
                            onClicked: root.currentPage = "settings"
                        }

                        QuickToggle {
                            width: (parent.width - 16) / 3
                            title: "DND"
                            subtitle: root.notificationHost && root.notificationHost.doNotDisturb
                                ? "Muted" : "Preview on"
                            icon: root.notificationHost && root.notificationHost.doNotDisturb ? "󰂛" : "󰂚"
                            active: root.notificationHost ? root.notificationHost.doNotDisturb : false
                            available: root.notificationHost !== null
                            onClicked: root.toggleDnd()
                        }
                    }

                    AudioSection { width: parent.width }
                    MediaSection { width: parent.width }
                    SystemSection { width: parent.width; active: root.isOpen && root.currentPage === "main" }

                    QuickActions {
                        width: parent.width
                        onWallpaperRequested: root.runAfterClose("wallpaper")
                        onAudioRequested: root.currentPage = "audio"
                        onPowerRequested: root.runAfterClose("power")
                    }
                }
            }

            AudioDevicesPage {
                id: audioPage
                anchors.fill: parent
                anchors.margins: 16
                opacity: root.currentPage === "audio" ? root.contentProgress : 0.0
                x: root.currentPage === "audio" ? 0 : 26
                enabled: root.currentPage === "audio" && root.isOpen

                Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                onBackRequested: root.currentPage = "main"
                onCloseRequested: root.close()
            }

            SettingsPage {
                id: settingsPage
                anchors.fill: parent
                anchors.margins: 16
                opacity: root.currentPage === "settings" ? root.contentProgress : 0.0
                x: root.currentPage === "settings" ? 0 : 26
                enabled: root.currentPage === "settings" && root.isOpen

                Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                onBackRequested: root.currentPage = "main"
                onMonitorRequested: root.currentPage = "monitor"
                onCloseRequested: root.close()
            }

            MonitorSettingsPage {
                id: monitorPage
                anchors.fill: parent
                anchors.margins: 16
                opacity: root.currentPage === "monitor" ? root.contentProgress : 0.0
                x: root.currentPage === "monitor" ? 0 : 26
                enabled: root.currentPage === "monitor" && root.isOpen

                Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                onBackRequested: root.currentPage = "settings"
                onCloseRequested: root.close()
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 1
                color: Qt.rgba(55/255,245/255,235/255,0.11)
            }
        }

        Rectangle {
            anchors.fill: glassCard
            radius: 20
            color: "transparent"
            border.width: 2
            border.color: "#37f5eb"
            opacity: root.borderProgress * 0.46
            enabled: false
        }
    }
}
