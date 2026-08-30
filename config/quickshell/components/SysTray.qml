import QtQuick
import Quickshell.Services.SystemTray

Item {
    id: sysTrayRoot

    property bool expanded: false

    property color accentColor: "#68787D"

    property int activePopupCount: 0

    readonly property bool popupActive: activePopupCount > 0

    property int buttonSize: 28
    property int drawerSpacing: 8

    property int openDuration: 280
    property int closeDuration: 220

    implicitWidth: buttonSize + drawerViewport.width + (drawerViewport.width > 0 ? drawerSpacing : 0)

    implicitHeight: 32

    width: implicitWidth
    height: implicitHeight

    function requestClose() {
        if (popupActive) {
            closeTimer.stop();
            return;
        }

        if (trayHover.hovered) {
            closeTimer.stop();
            return;
        }

        closeTimer.restart();
    }

    function popupOpened() {
        activePopupCount += 1;
        closeTimer.stop();
    }

    function popupClosed() {
        activePopupCount = Math.max(0, activePopupCount - 1);

        if (!popupActive && !trayHover.hovered)
            requestClose();
    }

    Timer {
        id: closeTimer

        interval: 450
        repeat: false

        onTriggered: {
            if (!sysTrayRoot.popupActive && !trayHover.hovered) {
                sysTrayRoot.expanded = false;
            }
        }
    }

    HoverHandler {
        id: trayHover

        onHoveredChanged: {
            if (hovered) {
                closeTimer.stop();
            } else {
                sysTrayRoot.requestClose();
            }
        }
    }

    Row {
        id: contentRow

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        spacing: drawerViewport.width > 0 ? sysTrayRoot.drawerSpacing : 0

        Item {
            id: drawerViewport

            anchors.verticalCenter: parent.verticalCenter

            width: sysTrayRoot.expanded ? trayRow.implicitWidth : 0

            height: 32

            clip: true

            Behavior on width {
                NumberAnimation {
                    duration: sysTrayRoot.expanded ? sysTrayRoot.openDuration : sysTrayRoot.closeDuration

                    easing.type: sysTrayRoot.expanded ? Easing.OutCubic : Easing.InCubic
                }
            }

            Row {
                id: trayRow

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                spacing: 8

                opacity: sysTrayRoot.expanded ? 1 : 0

                scale: sysTrayRoot.expanded ? 1.0 : 0.92

                transformOrigin: Item.Right

                Behavior on opacity {
                    NumberAnimation {
                        duration: sysTrayRoot.expanded ? 220 : 140

                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: sysTrayRoot.expanded ? 280 : 180

                        easing.type: sysTrayRoot.expanded ? Easing.OutBack : Easing.InCubic
                    }
                }

                Repeater {
                    id: trayRepeater

                    model: SystemTray.items

                    TrayItem {
                        item: modelData
                        accentColor: sysTrayRoot.accentColor

                        onPopupOpened: {
                            sysTrayRoot.popupOpened();
                        }

                        onPopupClosed: {
                            sysTrayRoot.popupClosed();
                        }
                    }
                }
            }
        }

        Item {
            id: drawerButton

            width: sysTrayRoot.buttonSize
            height: sysTrayRoot.buttonSize

            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                id: buttonBackground

                anchors.centerIn: parent

                width: 24
                height: 24

                radius: 8

                color: sysTrayRoot.expanded ? Qt.rgba(sysTrayRoot.accentColor.r, sysTrayRoot.accentColor.g, sysTrayRoot.accentColor.b, 0.12) : drawerMouse.containsMouse ? Qt.rgba(sysTrayRoot.accentColor.r, sysTrayRoot.accentColor.g, sysTrayRoot.accentColor.b, 0.08) : "transparent"

                border.width: sysTrayRoot.expanded ? 1 : drawerMouse.containsMouse ? 1 : 0

                border.color: sysTrayRoot.expanded ? Qt.rgba(sysTrayRoot.accentColor.r, sysTrayRoot.accentColor.g, sysTrayRoot.accentColor.b, 0.45) : Qt.rgba(sysTrayRoot.accentColor.r, sysTrayRoot.accentColor.g, sysTrayRoot.accentColor.b, 0.20)

                Behavior on color {
                    ColorAnimation {
                        duration: 140
                    }
                }

                Behavior on border.width {
                    NumberAnimation {
                        duration: 140
                    }
                }

                Behavior on border.color {
                    ColorAnimation {
                        duration: 140
                    }
                }
            }

            Text {
                id: drawerIcon

                anchors.centerIn: parent

                text: "󰀻"

                color: sysTrayRoot.expanded ? Qt.rgba(sysTrayRoot.accentColor.r, sysTrayRoot.accentColor.g, sysTrayRoot.accentColor.b, 0.95) : drawerMouse.containsMouse ? Qt.rgba(sysTrayRoot.accentColor.r, sysTrayRoot.accentColor.g, sysTrayRoot.accentColor.b, 0.85) : Qt.rgba(1, 1, 1, 0.72)

                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16

                scale: sysTrayRoot.expanded ? 1.08 : 1.0

                Behavior on color {
                    ColorAnimation {
                        duration: 140
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutBack
                    }
                }
            }

            MouseArea {
                id: drawerMouse

                anchors.fill: parent

                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                acceptedButtons: Qt.LeftButton

                onClicked: {
                    closeTimer.stop();

                    if (sysTrayRoot.popupActive)
                        return;
                    sysTrayRoot.expanded = !sysTrayRoot.expanded;
                }
            }
        }
    }
}
