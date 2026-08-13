import QtQuick

Rectangle {
    id: root

    property string icon: "󰘚"
    property string title: "Toggle"
    property string subtitle: ""
    property bool active: false
    property bool available: true
    property bool interactive: true

    signal clicked()

    implicitWidth: 190
    implicitHeight: 64
    radius: 20

    color: mouse.containsMouse && root.interactive
        ? Qt.rgba(18/255, 28/255, 36/255, 0.84)
        : Qt.rgba(10/255, 14/255, 21/255, 0.58)

    border.width: 1
    border.color: root.active
        ? Qt.rgba(55/255, 245/255, 235/255, 0.38)
        : Qt.rgba(255/255, 255/255, 255/255, 0.07)

    opacity: root.available ? 1.0 : 0.42

    Behavior on color { ColorAnimation { duration: 130 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    Row {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 11

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: root.active || (mouse.containsMouse && root.interactive)
                ? "#37f5eb"
                : Qt.rgba(1, 1, 1, 0.78)
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 20
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, parent.width - 44)
            spacing: 2

            Text {
                width: parent.width
                text: root.title
                color: "#e7f1f2"
                font.family: "Inter"
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: root.subtitle
                color: root.active
                    ? Qt.rgba(55/255, 245/255, 235/255, 0.72)
                    : Qt.rgba(1, 1, 1, 0.44)
                font.family: "Inter"
                font.pixelSize: 9
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.available && root.interactive
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
