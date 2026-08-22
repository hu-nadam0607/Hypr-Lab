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
    readonly property bool hasPlayer: player !== null
    readonly property string wallpaperStateFile: Quickshell.env("HOME") + "/.cache/hypr-lab/current-wallpaper"
    readonly property string fallbackWallpaper: Quickshell.env("HOME") + "/.config/hypr/hyprlab-wpp/HL_WP1.png"

    property bool introFinished: false

    function choosePlayer() {
        const list = Mpris.players.values
        let selected = null

        for (let i = 0; i < list.length; ++i) {
            if (list[i] && list[i].isPlaying) {
                selected = list[i]
                break
            }
        }

        if (!selected && list.length > 0)
            selected = list[0]

        player = selected
    }

    function fmtTime(seconds) {
        if (!isFinite(seconds) || seconds < 0)
            return "0:00"

        const s = Math.floor(seconds)
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }

    function mediaTitle() {
        if (!player)
            return "No media playing"

        const artist = player.trackArtist || ""
        const title = player.trackTitle || ""

        if (artist && title)
            return artist + "  —  " + title
        if (title)
            return title
        if (artist)
            return artist

        return "Media player ready"
    }

    onMediaPlayersChanged: choosePlayer()

    Timer {
        interval: 500
        repeat: true
        running: true
        onTriggered: surface.choosePlayer()
    }

    Process {
        running: true
        command: [
            "sh",
            "-c",
            'if [ -s "$1" ]; then cat "$1"; elif [ -f "$2" ]; then printf "%s\\n" "$2"; fi',
            "sh",
            surface.wallpaperStateFile,
            surface.fallbackWallpaper
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim()
                if (p.length > 0)
                    surface.wallpaperPath = p
            }
        }
    }

    Process {
        id: accentReader
        running: true
        command: [
            "sh",
            "-c",
            'f="$HOME/.cache/hypr-lab/border-color"; if [ -s "$f" ]; then cat "$f"; else printf "68787D\\n"; fi'
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim().replace(/^#/, "")
                if (/^[0-9A-Fa-f]{6}$/.test(v))
                    surface.accentHex = v.toUpperCase()
            }
        }
    }

    Timer {
        interval: 700
        repeat: true
        running: true
        onTriggered: {
            if (!accentReader.running)
                accentReader.running = true
        }
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        anchors.margins: -42

        source:
            surface.wallpaperPath.length > 0
            ? "file://" + surface.wallpaperPath
            : ""

        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        smooth: true
        mipmap: true

        scale: 1.025

        Behavior on scale {
            NumberAnimation {
                duration: 620
                easing.type: Easing.OutCubic
            }
        }
    }

    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        blurEnabled: true
        blur: 0.10
        blurMax: 18
    }

    Rectangle {
        id: dimLayer
        anchors.fill: parent
        color: Qt.rgba(5 / 255, 8 / 255, 12 / 255, 0.26)
        opacity: 0.42
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // ---------------------------------------------------------------------
    // Top system controls. Functional state remains independent of lock UI.
    // ---------------------------------------------------------------------
    Row {
        id: systemActions

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.round(Math.max(24, surface.height * 0.028))

        spacing: 24

        property real enterOffsetY: -10
        opacity: 0

        transform: Translate {
            id: systemActionsShift
            y: systemActions.enterOffsetY
        }

        Repeater {
            model: [
                { label: "Logout", icon: "󰍃", cmd: ["hyprctl", "dispatch", "exit"] },
                { label: "Reboot", icon: "󰜉", cmd: ["systemctl", "reboot"] },
                { label: "Shutdown", icon: "󰐥", cmd: ["systemctl", "poweroff"] }
            ]

            delegate: Item {
                id: actionButton

                required property var modelData

                width: 118
                height: 36

                readonly property bool hovered: actionMouse.containsMouse

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
                                  0.38
                              )

                        fillColor:
                            actionButton.hovered
                            ? Qt.rgba(
                                  surface.accentColor.r,
                                  surface.accentColor.g,
                                  surface.accentColor.b,
                                  0.10
                              )
                            : Qt.rgba(8 / 255, 12 / 255, 17 / 255, 0.38)

                        startX: 8
                        startY: 0
                        PathLine { x: actionButton.width; y: 0 }
                        PathLine { x: actionButton.width - 8; y: actionButton.height }
                        PathLine { x: 0; y: actionButton.height }
                        PathLine { x: 8; y: 0 }
                    }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: actionButton.modelData.icon
                        color: Qt.rgba(1, 1, 1, 0.72)
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 13
                    }

                    Text {
                        text: actionButton.modelData.label
                        color: Qt.rgba(1, 1, 1, 0.78)
                        font.family: "Inter"
                        font.pixelSize: 10
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

    // ---------------------------------------------------------------------
    // Editorial clock/date block. No HUD frame; typography does the work.
    // ---------------------------------------------------------------------
    Column {
        id: timeBlock

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.round(Math.max(118, surface.height * 0.115))

        spacing: 6

        opacity: 1

        Text {
            id: hourText
            anchors.horizontalCenter: parent.horizontalCenter

            opacity: 0

            transform: Translate {
                id: hourShift
                y: -8
            }

            text: clock.date.toLocaleTimeString(Qt.locale("hu_HU"), "HH")

            color: Qt.rgba(1, 1, 1, 0.93)
            font.family: "JetBrains Mono"
            font.pixelSize: Math.round(Math.max(70, Math.min(94, surface.height * 0.086)))
            font.weight: Font.ExtraLight
            font.letterSpacing: 5
        }

        // Hour / minute separator: visible in the center, fully dissolved at
        // both ends so it reads as a quiet divider rather than a HUD element.
        Item {
            id: clockDivider
            anchors.horizontalCenter: parent.horizontalCenter

            readonly property real fullWidth:
                Math.round(Math.max(150, Math.min(220, surface.width * 0.085)))
            property real reveal: 0

            width: fullWidth * reveal
            height: 3
            opacity: 0

            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: 2

                gradient: Gradient {
                    orientation: Gradient.Horizontal

                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(1, 1, 1, 0.0)
                    }
                    GradientStop {
                        position: 0.22
                        color: Qt.rgba(1, 1, 1, 0.12)
                    }
                    GradientStop {
                        position: 0.50
                        color: Qt.rgba(1, 1, 1, 0.44)
                    }
                    GradientStop {
                        position: 0.78
                        color: Qt.rgba(1, 1, 1, 0.12)
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(1, 1, 1, 0.0)
                    }
                }
            }
        }

        Text {
            id: minuteText
            anchors.horizontalCenter: parent.horizontalCenter

            opacity: 0

            transform: Translate {
                id: minuteShift
                y: 8
            }

            text: clock.date.toLocaleTimeString(Qt.locale("hu_HU"), "mm")

            color: Qt.rgba(1, 1, 1, 0.93)
            font.family: "JetBrains Mono"
            font.pixelSize: Math.round(Math.max(70, Math.min(94, surface.height * 0.086)))
            font.weight: Font.ExtraLight
            font.letterSpacing: 5
        }

        Text {
            id: dateText
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 3

            opacity: 0

            transform: Translate {
                id: dateShift
                y: 5
            }

            text: clock.date.toLocaleDateString(Qt.locale("hu_HU"), "yyyy · MM · dd.")

            color: Qt.rgba(1, 1, 1, 0.68)
            font.family: "Inter"
            font.pixelSize: Math.round(Math.max(12, Math.min(15, surface.height * 0.013)))
            font.letterSpacing: 3.4
        }

        Text {
            id: dayText
            anchors.horizontalCenter: parent.horizontalCenter

            opacity: 0

            transform: Translate {
                id: dayShift
                y: 5
            }

            text: clock.date.toLocaleDateString(Qt.locale("hu_HU"), "dddd").toUpperCase()

            color: surface.accentColor
            font.family: "Inter"
            font.pixelSize: Math.round(Math.max(11, Math.min(14, surface.height * 0.012)))
            font.weight: Font.Medium
            font.letterSpacing: 5.2
        }
    }

    // ---------------------------------------------------------------------
    // Login panel: sharp / angled / wallpaper-adaptive, intentionally quiet.
    // ---------------------------------------------------------------------
    Item {
        id: loginCard

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: timeBlock.bottom
        anchors.topMargin: 28

        width: Math.round(Math.max(390, Math.min(470, surface.width * 0.19)))
        height: Math.round(Math.max(200, Math.min(228, surface.height * 0.205)))

        property real shakeOffset: 0
        property real enterOffsetY: 14

        opacity: 0
        scale: 0.98

        transform: Translate {
            id: loginCardShift
            x: loginCard.shakeOffset
            y: loginCard.enterOffsetY
        }

        Shape {
            anchors.fill: parent

            ShapePath {
                strokeWidth: 1.25
                strokeColor:
                    Qt.rgba(
                        surface.accentColor.r,
                        surface.accentColor.g,
                        surface.accentColor.b,
                        0.72
                    )

                fillColor: Qt.rgba(8 / 255, 12 / 255, 17 / 255, 0.61)

                // Symmetric mirrored side slopes.
                // Both side edges lean to the right with the same angle.
                // Left:  bottom 0 -> top 28
                // Right: bottom width-28 -> top width
                startX: 28
                startY: 0
                PathLine { x: loginCard.width; y: 0 }
                PathLine { x: loginCard.width - 28; y: loginCard.height }
                PathLine { x: 0; y: loginCard.height }
                PathLine { x: 28; y: 0 }
            }
        }

        Column {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: -6
            spacing: 12

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 54
                height: 54
                radius: 27

                color: Qt.rgba(1, 1, 1, 0.055)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.20)

                Text {
                    anchors.centerIn: parent
                    text: "󰀄"
                    color: Qt.rgba(1, 1, 1, 0.88)
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 27
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: controller.username

                color: Qt.rgba(1, 1, 1, 0.86)
                font.family: "Inter"
                font.pixelSize: 14
                font.weight: Font.Medium
            }

            Item {
                id: passwordBox

                width: 320
                height: 42

                Shape {
                    anchors.fill: parent

                    ShapePath {
                        strokeWidth: 1.2
                        strokeColor:
                            controller.authMessage.length > 0
                            ? "#e66b6b"
                            : Qt.rgba(
                                  surface.accentColor.r,
                                  surface.accentColor.g,
                                  surface.accentColor.b,
                                  0.78
                              )

                        fillColor: Qt.rgba(3 / 255, 6 / 255, 10 / 255, 0.52)

                        // Same visual slope as the tall parent card.
                        startX: 6
                        startY: 0
                        PathLine { x: passwordBox.width; y: 0 }
                        PathLine { x: passwordBox.width - 6; y: passwordBox.height }
                        PathLine { x: 0; y: passwordBox.height }
                        PathLine { x: 6; y: 0 }
                    }
                }

                TextInput {
                    id: passwordInput

                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 30

                    verticalAlignment: TextInput.AlignVCenter

                    color: "white"
                    selectionColor: surface.accentColor

                    font.family: "Inter"
                    font.pixelSize: 14

                    echoMode: TextInput.Password
                    passwordCharacter: "●"

                    enabled: !controller.authBusy && !controller.authSucceeded
                    focus: true

                    onAccepted: {
                        if (text.length > 0)
                            controller.authenticate(text)
                    }

                    Component.onCompleted: forceActiveFocus()
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter

                    visible:
                        passwordInput.text.length === 0
                        && !passwordInput.activeFocus

                    text: "Password"

                    color: Qt.rgba(1, 1, 1, 0.32)
                    font.family: "Inter"
                    font.pixelSize: 12
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 13
                    anchors.verticalCenter: parent.verticalCenter

                    text: "→"

                    color: Qt.rgba(1, 1, 1, 0.70)
                    font.family: "Inter"
                    font.pixelSize: 18
                }
            }

            Item {
                width: 320
                height: 15
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
                        ? Qt.rgba(1, 1, 1, 0.48)
                        : "#e98a8a"

                    font.family: "Inter"
                    font.pixelSize: 10

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 100
                        }
                    }
                }
            }
        }
    }

    // ---------------------------------------------------------------------
    // Always-visible media dock. Stable layout, no vertical jumping when
    // playback starts/stops. CAVA only becomes active when audio is playing.
    // ---------------------------------------------------------------------
    Item {
        id: mediaDock

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(Math.max(24, surface.height * 0.028))

        width: Math.round(Math.max(620, Math.min(760, surface.width * 0.31)))
        height: 88

        property real enterOffsetY: 16
        opacity: 0

        transform: Translate {
            id: mediaDockShift
            y: mediaDock.enterOffsetY
        }

        Shape {
            anchors.fill: parent

            ShapePath {
                strokeWidth: 1
                strokeColor:
                    Qt.rgba(
                        surface.accentColor.r,
                        surface.accentColor.g,
                        surface.accentColor.b,
                        0.42
                    )

                fillColor: Qt.rgba(7 / 255, 10 / 255, 15 / 255, 0.58)

                startX: 16
                startY: 0
                PathLine { x: mediaDock.width; y: 0 }
                PathLine { x: mediaDock.width - 16; y: mediaDock.height }
                PathLine { x: 0; y: mediaDock.height }
                PathLine { x: 16; y: 0 }
            }
        }

        Rectangle {
            id: mediaIcon

            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter

            width: 52
            height: 52
            radius: 2

            color:
                Qt.rgba(
                    surface.accentColor.r,
                    surface.accentColor.g,
                    surface.accentColor.b,
                    surface.hasPlayer ? 0.10 : 0.045
                )

            Text {
                anchors.centerIn: parent

                text: surface.hasPlayer ? "󰎇" : "󰝛"

                color:
                    surface.hasPlayer
                    ? surface.accentColor
                    : Qt.rgba(1, 1, 1, 0.30)

                font.family: "Symbols Nerd Font"
                font.pixelSize: 24
            }
        }

        Column {
            id: mediaText

            anchors.left: mediaIcon.right
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter

            width: 250
            spacing: 3

            Text {
                width: parent.width
                elide: Text.ElideRight

                text: surface.mediaTitle()

                color:
                    surface.hasPlayer
                    ? Qt.rgba(1, 1, 1, 0.84)
                    : Qt.rgba(1, 1, 1, 0.38)

                font.family: "Inter"
                font.pixelSize: 11
                font.weight: Font.Medium
            }

            Text {
                width: parent.width
                elide: Text.ElideRight

                text:
                    surface.hasPlayer
                    ? surface.fmtTime(surface.player.position)
                      + "  /  "
                      + surface.fmtTime(surface.player.length)
                    : "Player idle"

                color:
                    surface.hasPlayer
                    ? Qt.rgba(1, 1, 1, 0.46)
                    : Qt.rgba(1, 1, 1, 0.25)

                font.family: "Inter"
                font.pixelSize: 9
                font.letterSpacing: 0.8
            }
        }

        CavaVisualizer {
            id: lockCava

            anchors.left: mediaText.right
            anchors.leftMargin: 18
            anchors.right: mediaControls.left
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter

            height: 34

            barCount: 34
            barSpacing: 3
            active: surface.musicPlaying

            barColor:
                Qt.rgba(
                    surface.accentColor.r,
                    surface.accentColor.g,
                    surface.accentColor.b,
                    surface.musicPlaying ? 0.70 : 0.24
                )
        }

        Row {
            id: mediaControls

            anchors.right: parent.right
            anchors.rightMargin: 22
            anchors.verticalCenter: parent.verticalCenter

            spacing: 18
            opacity: surface.hasPlayer ? 1 : 0.30

            Text {
                text: "󰒮"
                color: Qt.rgba(1, 1, 1, 0.72)
                font.family: "Symbols Nerd Font"
                font.pixelSize: 16

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    enabled: surface.hasPlayer
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: if (surface.player) surface.player.previous()
                }
            }

            Text {
                text: surface.musicPlaying ? "󰏤" : "󰐊"
                color: surface.hasPlayer ? surface.accentColor : Qt.rgba(1, 1, 1, 0.38)
                font.family: "Symbols Nerd Font"
                font.pixelSize: 18

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    enabled: surface.hasPlayer
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: if (surface.player) surface.player.togglePlaying()
                }
            }

            Text {
                text: "󰒭"
                color: Qt.rgba(1, 1, 1, 0.72)
                font.family: "Symbols Nerd Font"
                font.pixelSize: 16

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    enabled: surface.hasPlayer
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: if (surface.player) surface.player.next()
                }
            }
        }
    }

    // ---------------------------------------------------------------------
    // Lock / unlock motion. Session remains securely locked until PAM succeeds
    // and the controller's unlock timer releases WlSessionLock.
    // ---------------------------------------------------------------------
    // Editorial lock motion:
    // typography first, then the login card, then secondary controls.
    // The wallpaper motion runs underneath the full sequence.
    ParallelAnimation {
        id: introAnimation

        NumberAnimation {
            target: wallpaper
            property: "scale"
            from: 1.025
            to: 1.0
            duration: 720
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: dimLayer
            property: "opacity"
            from: 0.42
            to: 1.0
            duration: 560
            easing.type: Easing.OutCubic
        }

        SequentialAnimation {
            PauseAnimation { duration: 35 }

            // 1. Hour arrives first.
            ParallelAnimation {
                NumberAnimation {
                    target: hourText
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 130
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: hourShift
                    property: "y"
                    from: -8
                    to: 0
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }

            // 2. Divider draws outward while minutes settle in.
            ParallelAnimation {
                NumberAnimation {
                    target: clockDivider
                    property: "reveal"
                    from: 0
                    to: 1
                    duration: 150
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: clockDivider
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 110
                }
                NumberAnimation {
                    target: minuteText
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 140
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: minuteShift
                    property: "y"
                    from: 8
                    to: 0
                    duration: 165
                    easing.type: Easing.OutCubic
                }
            }

            // 3. Date and day appear as a quiet editorial caption.
            ParallelAnimation {
                NumberAnimation {
                    target: dateText
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 105
                }
                NumberAnimation {
                    target: dayText
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 125
                }
                NumberAnimation {
                    target: dateShift
                    property: "y"
                    from: 5
                    to: 0
                    duration: 130
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: dayShift
                    property: "y"
                    from: 5
                    to: 0
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }

            // 4. Login card floats gently into its fixed final position.
            ParallelAnimation {
                NumberAnimation {
                    target: loginCard
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 175
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: loginCard
                    property: "scale"
                    from: 0.98
                    to: 1.0
                    duration: 200
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: loginCard
                    property: "enterOffsetY"
                    from: 14
                    to: 0
                    duration: 205
                    easing.type: Easing.OutCubic
                }
            }

            // 5. Secondary controls arrive last.
            ParallelAnimation {
                NumberAnimation {
                    target: systemActions
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 130
                }
                NumberAnimation {
                    target: systemActions
                    property: "enterOffsetY"
                    from: -10
                    to: 0
                    duration: 155
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: mediaDock
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 145
                }
                NumberAnimation {
                    target: mediaDock
                    property: "enterOffsetY"
                    from: 16
                    to: 0
                    duration: 175
                    easing.type: Easing.OutCubic
                }
            }

            ScriptAction {
                script: surface.introFinished = true
            }
        }
    }

    // Unlock is deliberately shorter than the controller's 560 ms unlock timer,
    // so the visual exit completes while the session is still securely locked.
    ParallelAnimation {
        id: successExit

        NumberAnimation {
            target: loginCard
            property: "opacity"
            to: 0
            duration: 190
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: loginCard
            property: "scale"
            to: 0.985
            duration: 220
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: loginCard
            property: "enterOffsetY"
            to: 10
            duration: 220
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: timeBlock
            property: "opacity"
            to: 0
            duration: 300
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: systemActions
            property: "opacity"
            to: 0
            duration: 180
        }

        NumberAnimation {
            target: systemActions
            property: "enterOffsetY"
            to: -8
            duration: 210
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: mediaDock
            property: "opacity"
            to: 0
            duration: 205
        }

        NumberAnimation {
            target: mediaDock
            property: "enterOffsetY"
            to: 12
            duration: 230
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: dimLayer
            property: "opacity"
            to: 0.18
            duration: 470
            easing.type: Easing.InOutCubic
        }

        NumberAnimation {
            target: wallpaper
            property: "scale"
            to: 1.014
            duration: 500
            easing.type: Easing.InOutCubic
        }
    }

    Connections {
        target: controller

        function onAuthFailureSerialChanged() {
            passwordInput.text = ""
            passwordInput.forceActiveFocus()
            shakeAnimation.restart()
        }

        function onAuthSucceededChanged() {
            if (controller.authSucceeded)
                successExit.restart()
        }
    }

    SequentialAnimation {
        id: shakeAnimation

        NumberAnimation {
            target: loginCard
            property: "shakeOffset"
            to: -8
            duration: 55
        }

        NumberAnimation {
            target: loginCard
            property: "shakeOffset"
            to: 8
            duration: 80
        }

        NumberAnimation {
            target: loginCard
            property: "shakeOffset"
            to: -4
            duration: 65
        }

        NumberAnimation {
            target: loginCard
            property: "shakeOffset"
            to: 0
            duration: 55
        }
    }

    Component.onCompleted: {
        surface.choosePlayer()
        introAnimation.start()
    }
}
