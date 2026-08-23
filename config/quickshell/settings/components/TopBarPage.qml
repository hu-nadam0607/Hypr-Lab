import QtQuick

Item {
    id: root
    property var backend
    property color accentColor: "#68787D"

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight + 16
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: parent.width
            spacing: 0

            SectionLabel { width: parent.width; text: "LEFT"; accentColor: root.accentColor }

            SettingSwitch {
                width: parent.width
                accentColor: root.accentColor
                title: "Workspace buttons"
                subtitle: "Show the numbered workspace strip"
                checked: backend.topbarWorkspaces
                onToggled: function(v) {
                    backend.topbarWorkspaces = v
                    backend.setBool("TOPBAR_WORKSPACES", v)
                }
            }

            SectionLabel { width: parent.width; text: "RIGHT"; accentColor: root.accentColor }

            SettingSwitch {
                width: parent.width
                accentColor: root.accentColor
                title: "USB Manager"
                subtitle: "Show the removable-device button when USB storage is connected"
                checked: backend.topbarUsb
                onToggled: function(v) {
                    backend.topbarUsb = v
                    backend.setBool("TOPBAR_USB", v)
                }
            }

            SettingSwitch {
                width: parent.width
                accentColor: root.accentColor
                title: "Audio Control"
                subtitle: "Show the Top Bar volume button"
                checked: backend.topbarAudio
                onToggled: function(v) {
                    backend.topbarAudio = v
                    backend.setBool("TOPBAR_AUDIO", v)
                }
            }

            SettingSwitch {
                width: parent.width
                accentColor: root.accentColor
                title: "Notifications"
                subtitle: "Show the Notification panel button"
                checked: backend.topbarNotifications
                onToggled: function(v) {
                    backend.topbarNotifications = v
                    backend.setBool("TOPBAR_NOTIFICATIONS", v)
                }
            }

            SettingSwitch {
                width: parent.width
                accentColor: root.accentColor
                title: "Control Center"
                subtitle: "Show the Control Center button"
                checked: backend.topbarControlCenter
                onToggled: function(v) {
                    backend.topbarControlCenter = v
                    backend.setBool("TOPBAR_CONTROL_CENTER", v)
                }
            }

            SettingSwitch {
                width: parent.width
                accentColor: root.accentColor
                title: "Caps / Num indicators"
                subtitle: "Show keyboard lock state indicators"
                checked: backend.topbarLockIndicators
                onToggled: function(v) {
                    backend.topbarLockIndicators = v
                    backend.setBool("TOPBAR_LOCK_INDICATORS", v)
                }
            }

            SettingSwitch {
                width: parent.width
                accentColor: root.accentColor
                title: "System tray"
                subtitle: "Show the expandable system tray"
                checked: backend.topbarTray
                onToggled: function(v) {
                    backend.topbarTray = v
                    backend.setBool("TOPBAR_TRAY", v)
                }
            }

            SettingSwitch {
                width: parent.width
                accentColor: root.accentColor
                title: "Power button"
                subtitle: "Show the Power Menu button"
                checked: backend.topbarPower
                onToggled: function(v) {
                    backend.topbarPower = v
                    backend.setBool("TOPBAR_POWER", v)
                }
            }
        }
    }
}
