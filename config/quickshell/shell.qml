import Quickshell
import Quickshell.Wayland
import QtQuick
import "components"
import "components/controlcenter"

PanelWindow {
    id: shell

    anchors {
        top: true
        left: true
        right: true
    }

    color: "transparent"

    implicitHeight: 500

    exclusiveZone: 73

    mask: Region {
        Region {
            item: leftBar
        }

        Region {
            item: centerIsland
        }

        Region {
            item: rightBar
        }
    }

    WallpaperManager {
        id: globalWallpaperManager
    }

    PowerMenu {
        id: globalPowerMenu
    }

    AppLauncher {
        id: globalAppLauncher
    }

    Welcome {
        id: globalWelcome
    }

    ControlCenter {
        id: globalControlCenter
        notificationHost: centerIsland

        onWallpaperRequested: {
            globalWallpaperManager.togglePicker()
        }

        onPowerRequested: {
            globalPowerMenu.toggle()
        }
    }

    LeftBar {
        id: leftBar

        anchors.left:
            parent.left

        anchors.leftMargin:
            16

        anchors.top:
            parent.top

        anchors.topMargin:
            8

        onOpenAppLauncher:
            globalAppLauncher.toggle()
    }

    CenterIsland {
        id: centerIsland

        anchors.horizontalCenter:
            parent.horizontalCenter

        anchors.top:
            parent.top

        anchors.topMargin:
            8
    }

    PanelWindow {
        id: notificationDismissOverlay

        visible: centerIsland.notificationCenterOpen

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        aboveWindows: true
        focusable: true

        WlrLayershell.namespace: "hypr-lab-notification-dismiss"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        mask: Region {
            width: notificationDismissOverlay.width
            height: notificationDismissOverlay.height

            Region {
                x: Math.max(
                    0,
                    notificationDismissOverlay.width / 2
                        - centerIsland.width / 2
                        - 6
                )
                y: 2
                width: centerIsland.width + 12
                height: centerIsland.height + 12
                intersection: Intersection.Subtract
            }
        }

        Item {
            id: notificationKeyCatcher
            anchors.fill: parent
            focus: centerIsland.notificationCenterOpen

            Keys.onPressed: function(event) {
                if (
                    event.key === Qt.Key_Escape
                    && centerIsland.notificationCenterOpen
                ) {
                    centerIsland.closeNotificationCenter()
                    event.accepted = true
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton

            onClicked: {
                centerIsland.closeNotificationCenter()
            }
        }
    }

    UsbManager {
        id: globalUsbManager
    }

    RightBar {
        id: rightBar

        anchors.right:
            parent.right

        anchors.rightMargin:
            16

        anchors.top:
            parent.top

        anchors.topMargin:
            8

        usbAvailable: globalUsbManager.hasDevices

        onToggleUsbManager: function(anchorItem) {
            globalUsbManager.toggle(anchorItem)
        }

        onOpenControlCenter: {
            if (globalControlCenter.isOpen)
                globalControlCenter.close()
            else
                globalControlCenter.open()
        }

        onOpenPowerMenu:
            globalPowerMenu.toggle()
    }
}
