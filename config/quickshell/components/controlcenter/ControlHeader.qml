import QtQuick

Item {
    id: root

    signal closeRequested()
    implicitHeight: 34

    property string currentTime: Qt.formatTime(new Date(), "HH:mm")

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.currentTime = Qt.formatTime(new Date(), "HH:mm")
    }

    Column {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: -1

        Text {
            text: "HYPR-LAB // CONTROL"
            color: "#dce9ea"
            font.family: "Inter"
            font.pixelSize: 10
            font.bold: true
            font.letterSpacing: 1.7
        }
        Text {
            text: "SYSTEM DECK"
            color: Qt.rgba(55/255,245/255,235/255,0.44)
            font.family: "Inter"
            font.pixelSize: 7
            font.letterSpacing: 1.5
        }
    }

    Text {
        anchors.right: closeButton.left
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: root.currentTime
        color: Qt.rgba(1,1,1,0.48)
        font.family: "Inter"
        font.pixelSize: 11
        font.bold: true
    }

    Rectangle {
        id: closeButton
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 30
        height: 30
        radius: 15
        color: closeMouse.containsMouse ? Qt.rgba(55/255,245/255,235/255,0.08) : "transparent"

        Text {
            anchors.centerIn: parent
            text: "󰅖"
            color: closeMouse.containsMouse ? "#37f5eb" : Qt.rgba(1,1,1,0.54)
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 15
        }

        MouseArea {
            id: closeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.closeRequested()
        }
    }
}
