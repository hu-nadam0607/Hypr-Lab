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

    WlrLayershell.namespace: "hypr-lab-shell"

    implicitHeight: 500

    exclusiveZone: 40

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

    AdaptiveAccent {
        id: adaptiveAccent
    }

    WallpaperManager {
        id: globalWallpaperManager
        accentColor: adaptiveAccent.accentColor
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


    UnifiedTopBar {
        id: unifiedTopBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        barHeight: 36
        accentColor: adaptiveAccent.accentColor
        z: -10
    }

    LeftBar {
        id: leftBar

        anchors.left:
            parent.left

        anchors.leftMargin:
            8

        anchors.top:
            parent.top

        anchors.topMargin:
            0

        accentColor: adaptiveAccent.accentColor

        onOpenAppLauncher:
            globalAppLauncher.toggle()
    }

    CenterIsland {
        id: centerIsland

        anchors.horizontalCenter:
            parent.horizontalCenter

        anchors.horizontalCenterOffset:
            centerIsland.visualCenterCompensation

        anchors.top:
            parent.top

        anchors.topMargin:
            0

        accentColor: adaptiveAccent.accentColor
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
            8

        anchors.top:
            parent.top

        anchors.topMargin:
            0

        accentColor: adaptiveAccent.accentColor
        notificationHost: centerIsland

        usbAvailable: globalUsbManager.hasDevices

        onToggleUsbManager: function(anchorItem) {
            globalUsbManager.toggle(anchorItem)
        }

        onWallpaperRequested:
            globalWallpaperManager.togglePicker()

        onOpenPowerMenu:
            globalPowerMenu.toggle()
    }
}
