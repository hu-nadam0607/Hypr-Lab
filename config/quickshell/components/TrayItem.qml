import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Item {
    id: trayItemRoot

    property SystemTrayItem item: null

    signal popupOpened()
    signal popupClosed()

    property bool popupReportedOpen: false

    width: 28
    height: 28

    IconImage {
        id: trayIcon

        anchors.centerIn: parent

        width: 18
        height: 18

        source:
            trayItemRoot.item
            ? trayItemRoot.item.icon
            : ""

        opacity:
            mouseArea.containsMouse
            ? 1.0
            : 0.78

        scale:
            mouseArea.containsMouse
            ? 1.08
            : 1.0

        Behavior on opacity {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }
    }

    TrayMenu {
        id: trayMenu

        menu:
            trayItemRoot.item
            ? trayItemRoot.item.menu
            : null

        anchorItem: trayItemRoot

        onVisibleChanged: {
            if (visible) {
                if (!trayItemRoot.popupReportedOpen) {
                    trayItemRoot.popupReportedOpen = true
                    trayItemRoot.popupOpened()
                }
            } else {
                if (trayItemRoot.popupReportedOpen) {
                    trayItemRoot.popupReportedOpen = false
                    trayItemRoot.popupClosed()
                }
            }
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        acceptedButtons:
            Qt.LeftButton |
            Qt.RightButton

        onClicked: function(mouse) {
            if (!trayItemRoot.item)
                return

            if (mouse.button === Qt.LeftButton) {
                trayItemRoot.item.activate()
                return
            }

            if (mouse.button === Qt.RightButton) {
                if (!trayItemRoot.item.hasMenu)
                    return

                trayMenu.showMenu()
            }
        }
    }
}
