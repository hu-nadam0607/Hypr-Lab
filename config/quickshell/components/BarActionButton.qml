import QtQuick

Item {
    id: root

    property string icon: ""
    property int iconSize: 17
    property color normalColor: Qt.rgba(1, 1, 1, 0.72)
    property color hoverColor: Qt.rgba(55 / 255, 245 / 255, 235 / 255, 0.95)

    signal clicked()

    width: 28
    height: 28

    Rectangle {
        anchors.centerIn: parent
        width: 24
        height: 24
        radius: 8

        color: mouseArea.containsMouse
               ? Qt.rgba(55 / 255, 245 / 255, 235 / 255, 0.08)
               : "transparent"

        border.width: mouseArea.containsMouse ? 1 : 0
        border.color: Qt.rgba(55 / 255, 245 / 255, 235 / 255, 0.22)

        Behavior on color { ColorAnimation { duration: 130 } }
        Behavior on border.width { NumberAnimation { duration: 130 } }
    }

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: mouseArea.containsMouse ? root.hoverColor : root.normalColor
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: root.iconSize

        scale: mouseArea.containsMouse ? 1.07 : 1.0

        Behavior on color { ColorAnimation { duration: 130 } }
        Behavior on scale {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: root.clicked()
    }
}
