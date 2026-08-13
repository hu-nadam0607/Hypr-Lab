//@ pragma UseQApplication

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

    // A Notification Centernek kell
    // a függőleges hely.
    implicitHeight: 500

    // Csak a felső sáv foglal helyet.
    exclusiveZone: 73

    // ============================================================
    // CLICK-THROUGH MASK
    // ============================================================

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

    // ============================================================
    // HYPR-LAB WALLPAPER ENGINE
    // ============================================================

    WallpaperManager {
        id: globalWallpaperManager
    }

    // ============================================================
    // POWER MENU
    // ============================================================

    PowerMenu {
        id: globalPowerMenu
    }

    // ============================================================
    // HYPR-LAB APP LAUNCHER
    // ============================================================

    AppLauncher {
        id: globalAppLauncher
    }

    // ============================================================
    // HYPR-LAB WELCOME
    // ============================================================

    Welcome {
        id: globalWelcome
    }

    // ============================================================
    // HYPR-LAB CONTROL CENTER
    // ============================================================

    ControlCenter {
        id: globalControlCenter
        notificationHost: centerIsland

        onWallpaperRequested: {
            globalWallpaperManager.togglePicker()
        }


        onPowerRequested: {
            // Ugyanaz a QML objektum nyílik, mint SUPER+SHIFT+P-re.
            globalPowerMenu.toggle()
        }
    }

    // ============================================================
    // LEFT BAR
    // ============================================================

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

    // ============================================================
    // CENTER ISLAND
    // ============================================================

    CenterIsland {
        id: centerIsland

        anchors.horizontalCenter:
            parent.horizontalCenter

        anchors.top:
            parent.top

        anchors.topMargin:
            8
    }

    // ============================================================
    // NOTIFICATION CENTER DISMISS OVERLAY
    //
    // Full-screen transparent input layer while the Notification Center
    // is open. A Region cutout leaves the CenterIsland itself clickable.
    // ============================================================

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

        // Only the area OUTSIDE the CenterIsland accepts pointer input.
        // The small margin keeps the cyan glow/border comfortably inside
        // the pass-through hole.
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

    // ============================================================
    // USB MANAGER
    // ============================================================

    UsbManager {
        id: globalUsbManager
    }

    // ============================================================
    // RIGHT BAR
    // ============================================================

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