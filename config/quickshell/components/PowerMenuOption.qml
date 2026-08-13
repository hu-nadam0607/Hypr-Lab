import QtQuick
import Quickshell.Io

Item {
    id: optionRoot

    // ============================================================
    // PUBLIC API
    // ============================================================

    property string iconText:
        "?"

    property string labelText:
        "Option"

    property var actionCommand:
        []

    // Shutdown / veszélyes művelet
    property bool danger:
        false

    // A PowerMenu vezérli.
    property bool shown:
        false

    // Nyitáskor egymás után jelennek meg.
    property int revealDelay:
        0

    signal triggered()

    // ============================================================
    // SIZE
    // ============================================================

    width:
        88

    height:
        68

    // ============================================================
    // REVEAL STATE
    // ============================================================

    state:
        shown
        ? "shown"
        : "hidden"

    opacity:
        0.0

    scale:
        0.90

    // ============================================================
    // STATES
    // ============================================================

    states: [
        State {
            name:
                "hidden"

            PropertyChanges {
                target:
                    optionRoot

                opacity:
                    0.0

                scale:
                    0.90
            }
        },

        State {
            name:
                "shown"

            PropertyChanges {
                target:
                    optionRoot

                opacity:
                    1.0

                scale:
                    1.0
            }
        }
    ]

    // ============================================================
    // OPEN / CLOSE ANIMATION
    // ============================================================

    transitions: [
        Transition {
            from:
                "hidden"

            to:
                "shown"

            SequentialAnimation {
                PauseAnimation {
                    duration:
                        optionRoot.revealDelay
                }

                ParallelAnimation {
                    NumberAnimation {
                        property:
                            "opacity"

                        duration:
                            180

                        easing.type:
                            Easing.OutCubic
                    }

                    NumberAnimation {
                        property:
                            "scale"

                        duration:
                            240

                        easing.type:
                            Easing.OutBack
                    }
                }
            }
        },

        Transition {
            from:
                "shown"

            to:
                "hidden"

            ParallelAnimation {
                NumberAnimation {
                    property:
                        "opacity"

                    duration:
                        100

                    easing.type:
                        Easing.InCubic
                }

                NumberAnimation {
                    property:
                        "scale"

                    duration:
                        120

                    easing.type:
                        Easing.InCubic
                }
            }
        }
    ]

    // ============================================================
    // COMMAND
    // ============================================================

    Process {
        id: execProc

        command:
            optionRoot.actionCommand
    }

    // ============================================================
    // HOVER CIRCLE
    // ============================================================

    Rectangle {
        id: hoverCircle

        anchors {
            horizontalCenter:
                parent.horizontalCenter

            top:
                parent.top

            topMargin:
                1
        }

        width:
            mouseArea.containsMouse
            ? 42
            : 36

        height:
            width

        radius:
            width / 2

        color:
            mouseArea.containsMouse
            ? (
                  optionRoot.danger
                  ? Qt.rgba(
                        255 / 255,
                        75 / 255,
                        85 / 255,
                        0.14
                    )
                  : Qt.rgba(
                        55 / 255,
                        245 / 255,
                        235 / 255,
                        0.11
                    )
              )
            : "transparent"

        border.width:
            mouseArea.containsMouse
            ? 1
            : 0

        border.color:
            optionRoot.danger
            ? Qt.rgba(
                  255 / 255,
                  85 / 255,
                  95 / 255,
                  0.34
              )
            : Qt.rgba(
                  55 / 255,
                  245 / 255,
                  235 / 255,
                  0.28
              )

        Behavior on width {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 140
            }
        }

        Behavior on border.width {
            NumberAnimation {
                duration: 120
            }
        }

        // ========================================================
        // ICON
        // ========================================================

        Text {
            anchors.centerIn:
                parent

            text:
                optionRoot.iconText

            color:
                mouseArea.containsMouse
                ? (
                      optionRoot.danger
                      ? "#ff737d"
                      : "#37f5eb"
                  )
                : Qt.rgba(
                      1,
                      1,
                      1,
                      0.78
                  )

            font.family:
                "Symbols Nerd Font Mono"

            font.pixelSize:
                optionRoot.danger
                ? 21
                : 20

            font.bold:
                false

            scale:
                mouseArea.containsMouse
                ? 1.10
                : 1.0

            Behavior on color {
                ColorAnimation {
                    duration: 140
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutBack
                }
            }
        }
    }

    // ============================================================
    // LABEL
    // ============================================================

    Text {
        anchors {
            horizontalCenter:
                parent.horizontalCenter

            bottom:
                parent.bottom
        }

        text:
            optionRoot.labelText

        color:
            mouseArea.containsMouse
            ? (
                  optionRoot.danger
                  ? Qt.rgba(
                        1,
                        0.55,
                        0.58,
                        0.95
                    )
                  : Qt.rgba(
                        1,
                        1,
                        1,
                        0.95
                    )
              )
            : Qt.rgba(
                  1,
                  1,
                  1,
                  0.48
              )

        font.family:
            "Inter"

        font.pixelSize:
            10

        font.weight:
            Font.Medium

        Behavior on color {
            ColorAnimation {
                duration: 140
            }
        }
    }

    // ============================================================
    // MOUSE
    // ============================================================

    MouseArea {
        id: mouseArea

        anchors.fill:
            parent

        hoverEnabled:
            true

        cursorShape:
            Qt.PointingHandCursor

        acceptedButtons:
            Qt.LeftButton

        onClicked: {
            optionRoot.triggered()

            execProc.running = false
            execProc.running = true
        }
    }
}