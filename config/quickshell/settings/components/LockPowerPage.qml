import QtQuick

Item {
    id: root

    required property var backend
    property color accentColor: "#68787D"

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight + 28
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 1900

        Column {
            id: content
            width: parent.width
            spacing: 0

            Text {
                width: parent.width
                height: 32
                text: "SESSION LOCK"
                color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.82)
                font.family: "Inter"
                font.pixelSize: 8
                font.bold: true
                font.italic: true
                font.letterSpacing: 1.4
                verticalAlignment: Text.AlignVCenter
            }

            SettingSwitch {
                width: parent.width
                accentColor: root.accentColor
                title: "Automatic lock"
                subtitle: "Show the Hypr-Lab Lock Screen after inactivity."
                checked: root.backend.autoLock
                onToggled: value => root.backend.setAutoLock(value)
            }

            SettingStepper {
                width: parent.width
                accentColor: root.accentColor
                title: "Lock after inactivity"
                subtitle: "Idle time before the session is locked."
                valueText: root.backend.lockMinutes + " min"
                enabled: root.backend.autoLock
                onDecrease: root.backend.setLockMinutes(root.backend.lockMinutes - 1)
                onIncrease: root.backend.setLockMinutes(root.backend.lockMinutes + 1)
            }

            Text {
                width: parent.width
                height: 38
                text: "DISPLAY"
                color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.82)
                font.family: "Inter"
                font.pixelSize: 8
                font.bold: true
                font.italic: true
                font.letterSpacing: 1.4
                verticalAlignment: Text.AlignVCenter
            }

            SettingSwitch {
                width: parent.width
                accentColor: root.accentColor
                title: "Turn display off while locked"
                subtitle: "Put connected monitors into DPMS standby after the lock point."
                checked: root.backend.displayOff
                enabled: root.backend.autoLock
                onToggled: value => root.backend.setDisplayOff(value)
            }

            SettingStepper {
                width: parent.width
                accentColor: root.accentColor
                title: "Display off after lock"
                subtitle: "Additional locked-idle time before monitor standby."
                valueText: root.backend.displayOffAfterLock + " min"
                enabled: root.backend.autoLock && root.backend.displayOff
                onDecrease: root.backend.setDisplayOffAfterLock(root.backend.displayOffAfterLock - 1)
                onIncrease: root.backend.setDisplayOffAfterLock(root.backend.displayOffAfterLock + 1)
            }

            Text {
                width: parent.width
                height: 38
                text: "SUSPEND"
                color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.82)
                font.family: "Inter"
                font.pixelSize: 8
                font.bold: true
                font.italic: true
                font.letterSpacing: 1.4
                verticalAlignment: Text.AlignVCenter
            }

            SettingSwitch {
                width: parent.width
                accentColor: root.accentColor
                title: "Automatic suspend"
                subtitle: "Suspend the computer after extended locked idle time."
                checked: root.backend.suspendEnabled
                enabled: root.backend.autoLock
                onToggled: value => root.backend.setSuspendEnabled(value)
            }

            SettingStepper {
                width: parent.width
                accentColor: root.accentColor
                title: "Suspend after lock"
                subtitle: "Additional locked-idle time before system suspend."
                valueText: root.backend.suspendAfterLock + " min"
                enabled: root.backend.autoLock && root.backend.suspendEnabled
                onDecrease: root.backend.setSuspendAfterLock(root.backend.suspendAfterLock - 1)
                onIncrease: root.backend.setSuspendAfterLock(root.backend.suspendAfterLock + 1)
            }

            Item { width: 1; height: 22 }

            Rectangle {
                width: parent.width
                height: 78
                color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.045)
                border.width: 1
                border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.18)

                Row {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    Text {
                        text: "󰌾"
                        color: root.accentColor
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Text { text: "Wake behavior"; color: Qt.rgba(1,1,1,0.82); font.family:"Inter"; font.pixelSize:10; font.bold:true; font.italic:true }
                        Text { text: "Keyboard, mouse and power-button wake are handled by the kernel / firmware."; color: Qt.rgba(1,1,1,0.38); font.family:"Inter"; font.pixelSize:8; font.italic:true }
                        Text { text: "Hypr-Lab restores DPMS and keeps the Lock Screen active after resume."; color: Qt.rgba(1,1,1,0.38); font.family:"Inter"; font.pixelSize:8; font.italic:true }
                    }
                }
            }
        }
    }
}
