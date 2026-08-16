import QtQuick

import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: powerMenuScope

    property bool isOpen: false

    property bool windowVisible: false

    property bool glassVisible: false
    property bool borderVisible: false
    property bool contentVisible: false

    function open() {
        closeGlassTimer.stop()
        closeWindowTimer.stop()

        borderOpenTimer.stop()
        contentOpenTimer.stop()

        isOpen = true
        windowVisible = true

        glassVisible = true

        borderOpenTimer.restart()
        contentOpenTimer.restart()
    }

    function close() {
        if (!windowVisible)
            return

        borderOpenTimer.stop()
        contentOpenTimer.stop()

        isOpen = false

        contentVisible = false

        borderVisible = false

        closeGlassTimer.restart()

        closeWindowTimer.restart()
    }

    function toggle() {
        if (isOpen)
            close()
        else
            open()
    }

    IpcHandler {
        target: "powermenu"

        function toggle() {
            powerMenuScope.toggle()
        }

        function open() {
            powerMenuScope.open()
        }

        function close() {
            powerMenuScope.close()
        }
    }

    Timer {
        id: borderOpenTimer

        interval: 130
        repeat: false

        onTriggered: {
            if (powerMenuScope.isOpen)
                powerMenuScope.borderVisible = true
        }
    }

    Timer {
        id: contentOpenTimer

        interval: 210
        repeat: false

        onTriggered: {
            if (powerMenuScope.isOpen)
                powerMenuScope.contentVisible = true
        }
    }

    Timer {
        id: closeGlassTimer

        interval: 125
        repeat: false

        onTriggered: {
            if (!powerMenuScope.isOpen)
                powerMenuScope.glassVisible = false
        }
    }

    Timer {
        id: closeWindowTimer

        interval: 310
        repeat: false

        onTriggered: {
            if (!powerMenuScope.isOpen)
                powerMenuScope.windowVisible = false
        }
    }

    PanelWindow {
        id: menuWindow

        visible:
            powerMenuScope.windowVisible

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        color:
            "transparent"

        exclusionMode:
            ExclusionMode.Ignore

        focusable:
            true

        aboveWindows:
            true

        WlrLayershell.namespace:
            "hypr-lab-power-menu"

        WlrLayershell.layer:
            WlrLayer.Overlay

        WlrLayershell.keyboardFocus:
            WlrKeyboardFocus.Exclusive

        FocusScope {
            anchors.fill:
                parent

            focus:
                menuWindow.visible

            Keys.onEscapePressed: {
                powerMenuScope.close()
            }

            Rectangle {
                id: backdrop

                anchors.fill:
                    parent

                color:
                    Qt.rgba(
                        5 / 255,
                        8 / 255,
                        12 / 255,
                        0.30
                    )

                opacity:
                    powerMenuScope.glassVisible
                    ? 1.0
                    : 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                MouseArea {
                    anchors.fill:
                        parent

                    onClicked: {
                        powerMenuScope.close()
                    }
                }

                Item {
                    id: capsuleWrapper

                    anchors.centerIn:
                        parent

                    width: 500
                    height: 92

                    opacity:
                        powerMenuScope.glassVisible
                        ? 1.0
                        : 0.0

                    scale:
                        powerMenuScope.glassVisible
                        ? 1.0
                        : 0.94

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 210
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 280
                            easing.type: Easing.OutBack
                        }
                    }

                    Rectangle {
                        anchors.centerIn:
                            parent

                        width:
                            parent.width + 10

                        height:
                            parent.height + 10

                        radius:
                            height / 2

                        color:
                            "transparent"

                        border.width:
                            1

                        border.color:
                            Qt.rgba(
                                55 / 255,
                                245 / 255,
                                235 / 255,
                                0.12
                            )

                        opacity:
                            powerMenuScope.borderVisible
                            ? 1.0
                            : 0.0

                        scale:
                            powerMenuScope.borderVisible
                            ? 1.0
                            : 0.97

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 220
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Rectangle {
                        id: glassCapsule

                        anchors.fill:
                            parent

                        radius:
                            height / 2

                        color:
                            Qt.rgba(
                                10 / 255,
                                14 / 255,
                                21 / 255,
                                0.68
                            )

                        antialiasing:
                            true

                        clip:
                            true

                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top

                                leftMargin: 20
                                rightMargin: 20
                                topMargin: 1
                            }

                            height:
                                1

                            color:
                                Qt.rgba(
                                    1,
                                    1,
                                    1,
                                    0.12
                                )
                        }

                        MouseArea {
                            anchors.fill:
                                parent

                            onClicked:
                                function(mouse) {
                                    mouse.accepted = true
                                }
                        }

                        Row {
                            id: optionRow

                            anchors.centerIn:
                                parent

                            spacing:
                                22

                            PowerMenuOption {
                                iconText:
                                    "󰌾"

                                labelText:
                                    "Lock"

                                shown:
                                    powerMenuScope.contentVisible

                                revealDelay:
                                    0

                                actionCommand: [
                                    "quickshell",
                                    "-p",
                                    Quickshell.env("HOME") + "/.config/quickshell/lock/shell.qml"
                                ]

                                onTriggered: {
                                    powerMenuScope.close()
                                }
                            }

                            PowerMenuOption {
                                iconText:
                                    "󰍃"

                                labelText:
                                    "Logout"

                                shown:
                                    powerMenuScope.contentVisible

                                revealDelay:
                                    45

                                actionCommand: [
                                    "hyprctl",
                                    "dispatch",
                                    "exit"
                                ]

                                onTriggered: {
                                    powerMenuScope.close()
                                }
                            }

                            PowerMenuOption {
                                iconText:
                                    "󰜉"

                                labelText:
                                    "Reboot"

                                shown:
                                    powerMenuScope.contentVisible

                                revealDelay:
                                    90

                                actionCommand: [
                                    "systemctl",
                                    "reboot"
                                ]

                                onTriggered: {
                                    powerMenuScope.close()
                                }
                            }

                            PowerMenuOption {
                                iconText:
                                    "⏻"

                                labelText:
                                    "Shutdown"

                                danger:
                                    true

                                shown:
                                    powerMenuScope.contentVisible

                                revealDelay:
                                    135

                                actionCommand: [
                                    "systemctl",
                                    "poweroff"
                                ]

                                onTriggered: {
                                    powerMenuScope.close()
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill:
                            parent

                        radius:
                            height / 2

                        color:
                            "transparent"

                        border.width:
                            1

                        border.color:
                            Qt.rgba(
                                55 / 255,
                                245 / 255,
                                235 / 255,
                                0.72
                            )

                        opacity:
                            powerMenuScope.borderVisible
                            ? 1.0
                            : 0.0

                        scale:
                            powerMenuScope.borderVisible
                            ? 1.0
                            : 0.965

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 190
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 220
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }
        }
    }
}
