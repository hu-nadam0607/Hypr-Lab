import QtQuick

Item {
    id: root
    implicitHeight: 42

    signal wallpaperRequested()
    signal audioRequested()
    signal powerRequested()

    Row {
        anchors.fill: parent
        spacing: 7

        Repeater {
            model: [
                { icon: "󰏔", label: "Wall", action: "wallpaper" },
                { icon: "󰒓", label: "Audio", action: "audio" },
                { icon: "󰐥", label: "Power", action: "power" }
            ]

            Rectangle {
                required property var modelData
                width: (parent.width - 14) / 3
                height: 40
                radius: 20
                color: actionMouse.containsMouse
                    ? Qt.rgba(55/255,245/255,235/255,0.08)
                    : Qt.rgba(1,1,1,0.035)
                border.width: 1
                border.color: actionMouse.containsMouse
                    ? Qt.rgba(55/255,245/255,235/255,0.20)
                    : Qt.rgba(1,1,1,0.05)

                Row {
                    anchors.centerIn: parent
                    spacing: 7
                    Text {
                        text: modelData.icon
                        color: actionMouse.containsMouse ? "#37f5eb" : "#cbd9da"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                    }
                    Text {
                        text: modelData.label
                        color: Qt.rgba(1,1,1,0.67)
                        font.family: "Inter"
                        font.pixelSize: 10
                        font.bold: true
                    }
                }

                MouseArea {
                    id: actionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.action === "wallpaper") root.wallpaperRequested()
                        else if (modelData.action === "audio") root.audioRequested()
                        else if (modelData.action === "power") root.powerRequested()
                    }
                }
            }
        }
    }
}
