import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland

WlSessionLockSurface {
    id: surface
    required property var controller
    color: "#090b10"

    property string wallpaperPath: ""
    property string accentHex: "68787D"
    property var player: null
    property var mediaPlayers: Mpris.players.values
    readonly property color accentColor: "#" + accentHex
    readonly property bool musicPlaying: player !== null && player.isPlaying
    readonly property string wallpaperStateFile: Quickshell.env("HOME") + "/.cache/hypr-lab/current-wallpaper"
    readonly property string fallbackWallpaper: Quickshell.env("HOME") + "/.config/hypr/hyprlab-wpp/HL_WP1.png"

    function choosePlayer() {
        const list = Mpris.players.values
        let selected = null
        for (let i = 0; i < list.length; ++i) {
            if (list[i] && list[i].isPlaying) { selected = list[i]; break }
        }
        if (!selected && list.length > 0) selected = list[0]
        player = selected
    }

    function fmtTime(seconds) {
        if (!isFinite(seconds) || seconds < 0) return "0:00"
        const s = Math.floor(seconds)
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }

    onMediaPlayersChanged: choosePlayer()

    Timer { interval: 500; repeat: true; running: true; onTriggered: surface.choosePlayer() }

    Process {
        running: true
        command: ["sh", "-c", 'if [ -s "$1" ]; then cat "$1"; elif [ -f "$2" ]; then printf "%s\\n" "$2"; fi', "sh", surface.wallpaperStateFile, surface.fallbackWallpaper]
        stdout: StdioCollector { onStreamFinished: { const p = text.trim(); if (p.length > 0) surface.wallpaperPath = p } }
    }

    Process {
        id: accentReader
        running: true
        command: ["sh", "-c", 'f="$HOME/.cache/hypr-lab/border-color"; if [ -s "$f" ]; then cat "$f"; else printf "68787D\\n"; fi']
        stdout: StdioCollector { onStreamFinished: { const v = text.trim().replace(/^#/, ""); if (/^[0-9A-Fa-f]{6}$/.test(v)) surface.accentHex = v.toUpperCase() } }
    }

    Timer { interval: 700; repeat: true; running: true; onTriggered: { if (!accentReader.running) accentReader.running = true } }

    Image {
        id: wallpaper
        anchors.fill: parent
        anchors.margins: -32
        source: surface.wallpaperPath.length > 0 ? "file://" + surface.wallpaperPath : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        smooth: true
        mipmap: true
    }

    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        blurEnabled: true
        blur: 0.16
        blurMax: 20
    }

    Rectangle { anchors.fill: parent; color: Qt.rgba(5/255, 8/255, 12/255, 0.20) }

    SystemClock { id: clock; precision: SystemClock.Seconds }

    Column {
        id: mainColumn
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.round(surface.height * 0.065) + 55
        spacing: 18

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 1
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: clock.date.toLocaleTimeString(Qt.locale("hu_HU"), "HH:mm")
                color: "white"; font.family: "Inter"; font.pixelSize: Math.round(Math.max(88, Math.min(104, surface.height * 0.092))); font.weight: Font.Light
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: clock.date.toLocaleDateString(Qt.locale("hu_HU"), "yyyy. MM. dd. - dddd")
                color: Qt.rgba(1,1,1,0.66); font.family: "Inter"; font.pixelSize: Math.round(Math.max(14, Math.min(17, surface.height * 0.015))); font.italic: true
            }
        }

        Item {
            id: loginCard
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.round(Math.max(360, Math.min(410, surface.width * 0.15))); height: Math.round(Math.max(270, Math.min(300, surface.height * 0.27)))
            property real shakeOffset: 0
            transform: Translate { x: loginCard.shakeOffset }

            Shape {
                anchors.fill: parent
                ShapePath {
                    strokeWidth: 2; strokeColor: surface.accentColor; fillColor: Qt.rgba(10/255,14/255,20/255,0.68)
                    startX: 24; startY: 0
                    PathLine { x: loginCard.width; y: 0 }
                    PathLine { x: loginCard.width; y: loginCard.height - 24 }
                    PathLine { x: loginCard.width - 24; y: loginCard.height }
                    PathLine { x: 0; y: loginCard.height }
                    PathLine { x: 0; y: 24 }
                    PathLine { x: 24; y: 0 }
                }
            }

            Column {
                anchors.centerIn: parent; spacing: 17
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 78; height: 78; radius: 39
                    color: Qt.rgba(1,1,1,0.055); border.width: 1; border.color: Qt.rgba(surface.accentColor.r, surface.accentColor.g, surface.accentColor.b, 0.72)
                    Text { anchors.centerIn: parent; text: "󰀄"; color: Qt.rgba(1,1,1,0.86); font.family: "Symbols Nerd Font"; font.pixelSize: 38 }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter; text: controller.username
                    color: Qt.rgba(1,1,1,0.88); font.family: "Inter"; font.pixelSize: 15; font.weight: Font.DemiBold
                }
                Item {
                    id: passwordBox
                    width: 300; height: 44
                    Shape {
                        anchors.fill: parent
                        ShapePath {
                            strokeWidth: 1.5
                            strokeColor: controller.authMessage.length > 0 ? "#e66b6b" : surface.accentColor
                            fillColor: Qt.rgba(4/255,7/255,11/255,0.58)
                            startX: 10; startY: 0
                            PathLine { x: passwordBox.width; y: 0 }
                            PathLine { x: passwordBox.width - 10; y: passwordBox.height }
                            PathLine { x: 0; y: passwordBox.height }
                            PathLine { x: 10; y: 0 }
                        }
                    }
                    TextInput {
                        id: passwordInput
                        anchors.fill: parent; anchors.leftMargin: 17; anchors.rightMargin: 23
                        verticalAlignment: TextInput.AlignVCenter
                        color: "white"; selectionColor: surface.accentColor
                        font.family: "Inter"; font.pixelSize: 14
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        enabled: !controller.authBusy && !controller.authSucceeded
                        focus: true
                        onAccepted: { if (text.length > 0) controller.authenticate(text) }
                        Component.onCompleted: forceActiveFocus()
                    }
                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 17; anchors.verticalCenter: parent.verticalCenter
                        visible: passwordInput.text.length === 0 && !passwordInput.activeFocus
                        text: "Password"; color: Qt.rgba(1,1,1,0.34); font.family: "Inter"; font.pixelSize: 13
                    }
                }
                Item {
                    width: 300
                    height: 16
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        anchors.centerIn: parent
                        text:
                            controller.authBusy
                            ? "Hitelesítés…"
                            : controller.authMessage

                        opacity: text.length > 0 ? 1 : 0
                        color:
                            controller.authBusy
                            ? Qt.rgba(1,1,1,0.55)
                            : "#e98a8a"

                        font.family: "Inter"
                        font.pixelSize: 11

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 100
                            }
                        }
                    }
                }
            }
        }

    }

    // Fixed system-action row: always stays 40 px below the login card,
    // independent of CAVA/media visibility.
    Row {
        id: systemActions

        anchors.horizontalCenter: parent.horizontalCenter

        spacing: 46

        readonly property real loginBottom:
            loginCard.mapToItem(surface, 0, loginCard.height).y

        y:
            Math.round(
                loginBottom + 40
            )

        Repeater {
            model: [
                { label: "Logout", icon: "󰍃", cmd: ["hyprctl", "dispatch", "exit"] },
                { label: "Reboot", icon: "󰜉", cmd: ["systemctl", "reboot"] },
                { label: "Shutdown", icon: "󰐥", cmd: ["systemctl", "poweroff"] }
            ]

            delegate: Item {
                id: actionButton

                required property var modelData

                width: 132
                height: 38

                readonly property bool hovered:
                    actionMouse.containsMouse

                scale:
                    actionMouse.pressed
                    ? 0.97
                    : hovered
                        ? 0.99
                        : 1.0

                Behavior on scale {
                    NumberAnimation {
                        duration: 90
                        easing.type: Easing.OutCubic
                    }
                }

                Shape {
                    anchors.fill: parent

                    ShapePath {
                        strokeWidth: 1
                        strokeColor:
                            actionButton.hovered
                            ? surface.accentColor
                            : Qt.rgba(
                                  surface.accentColor.r,
                                  surface.accentColor.g,
                                  surface.accentColor.b,
                                  0.52
                              )

                        fillColor:
                            actionButton.hovered
                            ? Qt.rgba(
                                  surface.accentColor.r,
                                  surface.accentColor.g,
                                  surface.accentColor.b,
                                  0.12
                              )
                            : Qt.rgba(
                                  8 / 255,
                                  12 / 255,
                                  17 / 255,
                                  0.58
                              )

                        startX: 10
                        startY: 0
                        PathLine { x: actionButton.width; y: 0 }
                        PathLine { x: actionButton.width - 10; y: actionButton.height }
                        PathLine { x: 0; y: actionButton.height }
                        PathLine { x: 10; y: 0 }
                    }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: actionButton.modelData.icon
                        color: surface.accentColor
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 14
                    }

                    Text {
                        text: actionButton.modelData.label
                        color: Qt.rgba(1, 1, 1, 0.82)
                        font.family: "Inter"
                        font.pixelSize: 11
                        font.italic: true
                    }
                }

                MouseArea {
                    id: actionMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked:
                        Quickshell.execDetached(
                            actionButton.modelData.cmd
                        )
                }
            }
        }
    }

    Item {
        id: mediaDock
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: surface.musicPlaying ? Math.round(Math.max(92, Math.min(104, surface.height * 0.095))) : 0
        visible: surface.musicPlaying
        clip: true

        Rectangle { anchors.fill: parent; color: Qt.rgba(5/255,8/255,12/255,0.52) }
        Rectangle { anchors.left:parent.left; anchors.right:parent.right; anchors.top:parent.top; height:1; color:surface.accentColor }

        CavaVisualizer {
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            anchors.leftMargin: Math.round(Math.max(110, surface.width * 0.055)); anchors.rightMargin: Math.round(Math.max(110, surface.width * 0.055))
            height: 36; barCount: 96; barSpacing: 3
            active: surface.musicPlaying
            barColor: Qt.rgba(surface.accentColor.r,surface.accentColor.g,surface.accentColor.b,0.55)
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top; anchors.topMargin: 13; spacing: 24
            Text {
                width: Math.round(Math.max(460, Math.min(620, surface.width * 0.22))); elide: Text.ElideRight
                text: surface.player ? ((surface.player.trackArtist || "") + (surface.player.trackArtist && surface.player.trackTitle ? "  —  " : "") + (surface.player.trackTitle || "")) : ""
                color:Qt.rgba(1,1,1,0.84); font.family:"Inter"; font.pixelSize:12; font.weight:Font.DemiBold; anchors.verticalCenter:parent.verticalCenter
            }
            Row { spacing:18; anchors.verticalCenter:parent.verticalCenter
                Text { text:"󰒮"; color:Qt.rgba(1,1,1,0.72); font.family:"Symbols Nerd Font"; font.pixelSize:16; MouseArea{anchors.fill:parent;anchors.margins:-8;cursorShape:Qt.PointingHandCursor;onClicked:if(surface.player)surface.player.previous()} }
                Text { text:surface.musicPlaying?"󰏤":"󰐊"; color:surface.accentColor; font.family:"Symbols Nerd Font"; font.pixelSize:18; MouseArea{anchors.fill:parent;anchors.margins:-8;cursorShape:Qt.PointingHandCursor;onClicked:if(surface.player)surface.player.togglePlaying()} }
                Text { text:"󰒭"; color:Qt.rgba(1,1,1,0.72); font.family:"Symbols Nerd Font"; font.pixelSize:16; MouseArea{anchors.fill:parent;anchors.margins:-8;cursorShape:Qt.PointingHandCursor;onClicked:if(surface.player)surface.player.next()} }
            }
            Text {
                text: surface.player ? surface.fmtTime(surface.player.position) + " / " + surface.fmtTime(surface.player.length) : ""
                color:Qt.rgba(1,1,1,0.52); font.family:"Inter"; font.pixelSize:11; anchors.verticalCenter:parent.verticalCenter
            }
        }
    }

    Connections {
        target: controller
        function onAuthFailureSerialChanged() {
            passwordInput.text = ""
            passwordInput.forceActiveFocus()
            shakeAnimation.restart()
        }
        function onAuthSucceededChanged() { if (controller.authSucceeded) successFade.restart() }
    }

    SequentialAnimation {
        id: shakeAnimation
        NumberAnimation { target: loginCard; property:"shakeOffset"; to:-8; duration:55 }
        NumberAnimation { target: loginCard; property:"shakeOffset"; to:8; duration:80 }
        NumberAnimation { target: loginCard; property:"shakeOffset"; to:-4; duration:65 }
        NumberAnimation { target: loginCard; property:"shakeOffset"; to:0; duration:55 }
    }

    NumberAnimation { id: successFade; target: mainColumn; property:"opacity"; to:0; duration:420; easing.type:Easing.InCubic }
}
