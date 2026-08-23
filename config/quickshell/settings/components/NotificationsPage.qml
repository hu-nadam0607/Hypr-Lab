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

            SectionLabel {
                width: parent.width
                text: "BEHAVIOR"
                accentColor: root.accentColor
            }

            SettingSwitch {
                width: parent.width
                accentColor: root.accentColor
                title: "Do Not Disturb"
                subtitle: "Suppress notification sounds while keeping notifications available"
                checked: backend.dnd
                onToggled: function(v) {
                    backend.setDnd(v)
                }
            }

            SettingSwitch {
                width: parent.width
                accentColor: root.accentColor
                title: "Notification sound"
                subtitle: "Play the Hypr-Lab notification sound"
                checked: backend.notificationSound
                onToggled: function(v) {
                    backend.notificationSound = v
                    backend.setBool("NOTIFICATION_SOUND", v)
                }
            }

            SettingSwitch {
                width: parent.width
                accentColor: root.accentColor
                title: "Center Island summary"
                subtitle: "Show notification count feedback in Center Island"
                checked: backend.notificationSummary
                onToggled: function(v) {
                    backend.notificationSummary = v
                    backend.setBool("NOTIFICATION_SUMMARY", v)
                }
            }

            SectionLabel {
                width: parent.width
                text: "HISTORY"
                accentColor: root.accentColor
            }

            SettingAction {
                width: parent.width
                accentColor: root.accentColor
                title: "Clear notifications"
                subtitle: "Dismiss all notifications currently tracked by Hypr-Lab"
                icon: "󰆴"
                buttonText: "CLEAR"
                onTriggered: backend.clearNotifications()
            }
        }
    }
}
