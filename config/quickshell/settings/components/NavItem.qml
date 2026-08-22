import QtQuick

Item {
    id: root

    property string icon: ""
    property string title: ""
    property string pageId: ""
    property bool selected: false
    property bool available: true
    property color accentColor: "#68787D"

    signal triggered(string pageId)

    height: 46

    Rectangle {
        anchors.fill: parent
        color: mouse.containsMouse
            ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.075)
            : "transparent"

        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 2
        color: root.selected ? root.accentColor : "transparent"
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 15
        anchors.verticalCenter: parent.verticalCenter
        spacing: 11

        Text {
            text: root.icon
            color: root.selected ? root.accentColor : Qt.rgba(1, 1, 1, root.available ? 0.58 : 0.25)
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 15
        }

        Text {
            text: root.title
            color: root.selected ? "white" : Qt.rgba(1, 1, 1, root.available ? 0.68 : 0.30)
            font.family: "Inter"
            font.pixelSize: 10
            font.bold: root.selected
            font.italic: true
        }
    }

    Text {
        visible: !root.available
        anchors.right: parent.right
        anchors.rightMargin: 13
        anchors.verticalCenter: parent.verticalCenter
        text: "SOON"
        color: Qt.rgba(1, 1, 1, 0.22)
        font.family: "Inter"
        font.pixelSize: 7
        font.bold: true
        font.letterSpacing: 1.1
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered(root.pageId)
    }
}
