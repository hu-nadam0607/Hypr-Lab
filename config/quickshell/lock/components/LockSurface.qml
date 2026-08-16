import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

WlSessionLockSurface {
    id: surface

    required property var controller

    color: "#090b10"

    property string wallpaperPath: ""
    property bool introFinished: false

    readonly property string wallpaperStateFile:
        Quickshell.env("HOME") + "/.cache/hypr-lab/current-wallpaper"

    readonly property string fallbackWallpaper:
        Quickshell.env("HOME") + "/.config/hypr/hyprlab-wpp/HL_WP1.png"

    Process {
        id: wallpaperStateReader

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
                const path =
                    text.trim()

                if (path.length > 0)
                    surface.wallpaperPath =
                        path
            }
        }
    }

    Item {
        id: scene

        anchors.fill:
            parent

        clip:
            true

        Image {
            id: wallpaper

            anchors.fill:
                parent

            anchors.margins:
                -36

            source:
                surface.wallpaperPath.length > 0
                ? "file://" + surface.wallpaperPath
                : ""

            fillMode:
                Image.PreserveAspectCrop

            asynchronous:
                true

            cache:
                false

            smooth:
                true

            mipmap:
                true

            visible:
                true
        }

        MultiEffect {
            anchors.fill:
                parent

            source:
                wallpaper

            blurEnabled:
                true

            blur:
                0.82

            blurMax:
                64
        }

        Rectangle {
            anchors.fill:
                parent

            color:
                Qt.rgba(
                    6 / 255,
                    9 / 255,
                    14 / 255,
                    0.52
                )
        }

        Rectangle {
            anchors.fill:
                parent

            color:
                Qt.rgba(
                    14 / 255,
                    227 / 255,
                    216 / 255,
                    0.025
                )
        }

        Column {
            id: content

            anchors.centerIn:
                parent

            anchors.verticalCenterOffset:
                -18

            spacing:
                26

            transform: Translate {
                id: contentTranslate

                y:
                    -surface.height
            }

            Column {
                anchors.horizontalCenter:
                    parent.horizontalCenter

                spacing:
                    4

                SystemClock {
                    id: clock

                    precision:
                        SystemClock.Minutes
                }

                Text {
                    anchors.horizontalCenter:
                        parent.horizontalCenter

                    text:
                        clock.date.toLocaleTimeString(
                            Qt.locale("hu_HU"),
                            "HH:mm"
                        )

                    color:
                        "white"

                    font.family:
                        "Inter"

                    font.pixelSize:
                        86

                    font.weight:
                        Font.Light

                    font.letterSpacing:
                        -2
                }

                Text {
                    anchors.horizontalCenter:
                        parent.horizontalCenter

                    text:
                        clock.date.toLocaleDateString(
                            Qt.locale("hu_HU"),
                            "yyyy. MMMM d., dddd"
                        )

                    color:
                        Qt.rgba(
                            1,
                            1,
                            1,
                            0.72
                        )

                    font.family:
                        "Inter"

                    font.pixelSize:
                        16

                    font.weight:
                        Font.Medium
                }
            }

            Rectangle {
                id: loginCard

                anchors.horizontalCenter:
                    parent.horizontalCenter

                anchors.horizontalCenterOffset:
                    shakeOffset

                property real shakeOffset:
                    0

                width:
                    410

                height:
                    176

                radius:
                    26

                color:
                    Qt.rgba(
                        15 / 255,
                        20 / 255,
                        28 / 255,
                        0.66
                    )

                border.width:
                    2

                border.color:
                    Qt.rgba(
                        55 / 255,
                        245 / 255,
                        235 / 255,
                        0.50
                    )

                Column {
                    anchors.centerIn:
                        parent

                    spacing:
                        16

                    Row {
                        anchors.horizontalCenter:
                            parent.horizontalCenter

                        spacing:
                            9

                        Text {
                            text:
                                "󰀄"

                            color:
                                Qt.rgba(
                                    55 / 255,
                                    245 / 255,
                                    235 / 255,
                                    0.92
                                )

                            font.family:
                                "Symbols Nerd Font"

                            font.pixelSize:
                                18
                        }

                        Text {
                            text:
                                controller.username

                            color:
                                Qt.rgba(
                                    1,
                                    1,
                                    1,
                                    0.90
                                )

                            font.family:
                                "Inter"

                            font.pixelSize:
                                15

                            font.weight:
                                Font.DemiBold
                        }
                    }

                    Rectangle {
                        id: passwordCapsule

                        width:
                            330

                        height:
                            48

                        radius:
                            24

                        color:
                            passwordInput.activeFocus
                            ? Qt.rgba(
                                  10 / 255,
                                  15 / 255,
                                  22 / 255,
                                  0.82
                              )
                            : Qt.rgba(
                                  10 / 255,
                                  15 / 255,
                                  22 / 255,
                                  0.62
                              )

                        border.width:
                            1

                        border.color:
                            controller.authMessage.length > 0
                            ? Qt.rgba(
                                  1.0,
                                  0.35,
                                  0.35,
                                  0.75
                              )
                            : passwordInput.activeFocus
                                ? Qt.rgba(
                                      55 / 255,
                                      245 / 255,
                                      235 / 255,
                                      0.82
                                  )
                                : Qt.rgba(
                                      1,
                                      1,
                                      1,
                                      0.12
                                  )

                        Behavior on border.color {
                            ColorAnimation {
                                duration:
                                    150
                            }
                        }

                        Row {
                            anchors.fill:
                                parent

                            anchors.leftMargin:
                                17

                            anchors.rightMargin:
                                17

                            spacing:
                                11

                            Text {
                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text:
                                    "󰌾"

                                color:
                                    Qt.rgba(
                                        55 / 255,
                                        245 / 255,
                                        235 / 255,
                                        0.76
                                    )

                                font.family:
                                    "Symbols Nerd Font"

                                font.pixelSize:
                                    17
                            }

                            Item {
                                anchors.verticalCenter:
                                    parent.verticalCenter

                                width:
                                    255

                                height:
                                    30

                                TextInput {
                                    id: passwordInput

                                    anchors.fill:
                                        parent

                                    color:
                                        "transparent"

                                    selectionColor:
                                        "transparent"

                                    selectedTextColor:
                                        "transparent"

                                    font.family:
                                        "Inter"

                                    font.pixelSize:
                                        15

                                    echoMode:
                                        TextInput.Normal

                                    enabled:
                                        !controller.authBusy
                                        && !controller.authSucceeded

                                    focus:
                                        true

                                    cursorVisible:
                                        false

                                    onAccepted: {
                                        if (text.length > 0)
                                            controller.authenticate(
                                                text
                                            )
                                    }

                                    Component.onCompleted:
                                        forceActiveFocus()
                                }

                                Row {
                                    id: passwordDots

                                    anchors.left:
                                        parent.left

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    height:
                                        parent.height

                                    spacing:
                                        8

                                    Repeater {
                                        model:
                                            passwordInput.text.length

                                        Rectangle {
                                            id: dot

                                            required property int index

                                            anchors.verticalCenter:
                                                parent.verticalCenter

                                            width:
                                                15

                                            height:
                                                15

                                            radius:
                                                7.5

                                            color:
                                                Qt.rgba(
                                                    5 / 255,
                                                    8 / 255,
                                                    12 / 255,
                                                    0.96
                                                )

                                            border.width:
                                                2

                                            border.color:
                                                Qt.rgba(
                                                    55 / 255,
                                                    245 / 255,
                                                    235 / 255,
                                                    0.95
                                                )

                                            opacity:
                                                0

                                            scale:
                                                0.25

                                            Component.onCompleted:
                                                dotIn.restart()

                                            ParallelAnimation {
                                                id: dotIn

                                                NumberAnimation {
                                                    target:
                                                        dot

                                                    property:
                                                        "opacity"

                                                    from:
                                                        0

                                                    to:
                                                        1

                                                    duration:
                                                        120

                                                    easing.type:
                                                        Easing.OutQuad
                                                }

                                                NumberAnimation {
                                                    target:
                                                        dot

                                                    property:
                                                        "scale"

                                                    from:
                                                        0.25

                                                    to:
                                                        1

                                                    duration:
                                                        180

                                                    easing.type:
                                                        Easing.OutBack
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        id: passwordCursor

                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        width:
                                            2

                                        height:
                                            18

                                        radius:
                                            1

                                        color:
                                            Qt.rgba(
                                                55 / 255,
                                                245 / 255,
                                                235 / 255,
                                                0.95
                                            )

                                        visible:
                                            passwordInput.activeFocus
                                            && !controller.authBusy
                                            && !controller.authSucceeded

                                        SequentialAnimation on opacity {
                                            running:
                                                passwordCursor.visible

                                            loops:
                                                Animation.Infinite

                                            NumberAnimation {
                                                from:
                                                    1

                                                to:
                                                    1

                                                duration:
                                                    520
                                            }

                                            NumberAnimation {
                                                from:
                                                    1

                                                to:
                                                    0

                                                duration:
                                                    120
                                            }

                                            NumberAnimation {
                                                from:
                                                    0

                                                to:
                                                    0

                                                duration:
                                                    360
                                            }

                                            NumberAnimation {
                                                from:
                                                    0

                                                to:
                                                    1

                                                duration:
                                                    120
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        anchors.horizontalCenter:
                            parent.horizontalCenter

                        height:
                            18

                        text:
                            controller.authBusy
                            ? "Ellenőrzés…"
                            : controller.authMessage

                        color:
                            controller.authBusy
                            ? Qt.rgba(
                                  1,
                                  1,
                                  1,
                                  0.55
                              )
                            : Qt.rgba(
                                  1.0,
                                  0.48,
                                  0.48,
                                  0.90
                              )

                        font.family:
                            "Inter"

                        font.pixelSize:
                            12

                        opacity:
                            text.length > 0
                            ? 1
                            : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration:
                                    140
                            }
                        }
                    }
                }
            }
        }

        Text {
            id: footer

            anchors.horizontalCenter:
                parent.horizontalCenter

            anchors.bottom:
                parent.bottom

            anchors.bottomMargin:
                34

            text:
                "HYPR-LAB LOCK"

            color:
                Qt.rgba(
                    55 / 255,
                    245 / 255,
                    235 / 255,
                    0.48
                )

            font.family:
                "Inter"

            font.pixelSize:
                11

            font.bold:
                true

            font.letterSpacing:
                2.4
        }

        Connections {
            target:
                controller

            function onAuthFailureSerialChanged() {
                passwordInput.text = ""
                passwordInput.forceActiveFocus()
                shakeAnimation.restart()
            }

            function onAuthSucceededChanged() {
                if (controller.authSucceeded)
                    launchAnimation.restart()
            }
        }

        SequentialAnimation {
            id: introAnimation

            running:
                false

            NumberAnimation {
                target:
                    contentTranslate

                property:
                    "y"

                from:
                    -surface.height

                to:
                    24

                duration:
                    560

                easing.type:
                    Easing.OutCubic
            }

            NumberAnimation {
                target:
                    contentTranslate

                property:
                    "y"

                to:
                    -11

                duration:
                    145

                easing.type:
                    Easing.OutQuad
            }

            NumberAnimation {
                target:
                    contentTranslate

                property:
                    "y"

                to:
                    6

                duration:
                    105

                easing.type:
                    Easing.OutQuad
            }

            NumberAnimation {
                target:
                    contentTranslate

                property:
                    "y"

                to:
                    0

                duration:
                    90

                easing.type:
                    Easing.OutQuad
            }

            onFinished: {
                surface.introFinished = true
                passwordInput.forceActiveFocus()
            }
        }

        SequentialAnimation {
            id: launchAnimation

            running:
                false

            NumberAnimation {
                target:
                    contentTranslate

                property:
                    "y"

                to:
                    34

                duration:
                    165

                easing.type:
                    Easing.OutCubic
            }

            NumberAnimation {
                target:
                    contentTranslate

                property:
                    "y"

                to:
                    -surface.height
                    - content.height

                duration:
                    430

                easing.type:
                    Easing.InCubic
            }
        }

        SequentialAnimation {
            id: shakeAnimation

            running:
                false

            NumberAnimation {
                target:
                    loginCard

                property:
                    "shakeOffset"

                to:
                    -8

                duration:
                    55
            }

            NumberAnimation {
                target:
                    loginCard

                property:
                    "shakeOffset"

                to:
                    8

                duration:
                    80
            }

            NumberAnimation {
                target:
                    loginCard

                property:
                    "shakeOffset"

                to:
                    -5

                duration:
                    70
            }

            NumberAnimation {
                target:
                    loginCard

                property:
                    "shakeOffset"

                to:
                    0

                duration:
                    55
            }
        }

        Component.onCompleted:
            introAnimation.start()
    }
}
