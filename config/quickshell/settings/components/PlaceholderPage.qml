import QtQuick

Item {
    id: root

    property string title: ""
    property string description: ""
    property color accentColor: "#68787D"

    Column {
        anchors.centerIn: parent
        spacing: 14

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "󰅐"
            color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.56)
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 34
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.title
            color: Qt.rgba(1, 1, 1, 0.80)
            font.family: "Inter"
            font.pixelSize: 15
            font.bold: true
            font.italic: true
        }

        Text {
            width: 420
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: root.description
            color: Qt.rgba(1, 1, 1, 0.38)
            font.family: "Inter"
            font.pixelSize: 9
            font.italic: true
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "MODULE PLANNED"
            color: root.accentColor
            font.family: "Inter"
            font.pixelSize: 8
            font.bold: true
            font.letterSpacing: 1.7
        }
    }
}
