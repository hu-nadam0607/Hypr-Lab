import QtQuick

Item {
    id: root

    property string icon: ""
    property int iconSize: 15
    property color accentColor: "#68787D"
    property color normalColor: Qt.rgba(1, 1, 1, 0.72)
    property color hoverColor: accentColor
    property bool forceAccent: false

    signal clicked()

    width: 30
    height: 36

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.forceAccent ? root.accentColor : (mouseArea.containsMouse ? root.hoverColor : root.normalColor)
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: root.iconSize
        scale: mouseArea.containsMouse ? 1.08 : 1.0

        Behavior on color { ColorAnimation { duration: 110 } }
        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
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
