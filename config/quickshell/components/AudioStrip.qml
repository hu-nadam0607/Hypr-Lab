import QtQuick

Item {
    id: root
    property string icon: "󰕾"
    property string label: "Audio"
    property real value: 0.0
    property bool muted: false
    property color accentColor: "#68787D"
    signal valueRequested(real value)
    signal muteRequested()

    implicitHeight: 56

    Text {
        id: iconText
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: 5
        text: root.icon
        color: root.muted ? Qt.rgba(1,1,1,0.34) : root.accentColor
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 16
        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: root.muteRequested()
        }
    }

    Text {
        anchors.left: iconText.right
        anchors.leftMargin: 9
        anchors.right: valueText.left
        anchors.rightMargin: 8
        anchors.top: parent.top
        anchors.topMargin: 4
        text: root.label
        color: Qt.rgba(1,1,1,0.78)
        font.family: "Inter"
        font.italic: true
        font.pixelSize: 10
        font.bold: true
        elide: Text.ElideRight
    }

    Text {
        id: valueText
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 4
        text: Math.round(Math.max(0, root.value) * 100) + "%"
        color: root.muted ? Qt.rgba(1,1,1,0.34) : root.accentColor
        font.family: "Inter"
        font.italic: true
        font.pixelSize: 10
        font.bold: true
    }

    Item {
        id: slider
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 24

        Rectangle {
            id: track
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 5
            radius: 2
            color: Qt.rgba(1,1,1,0.10)
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.value))
                height: parent.height
                radius: 2
                color: root.muted ? Qt.rgba(1,1,1,0.18) : root.accentColor
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            function send(xPos) { root.valueRequested(Math.max(0, Math.min(1, xPos / width))) }
            onPressed: function(mouse) { send(mouse.x) }
            onPositionChanged: function(mouse) { if (pressed) send(mouse.x) }
        }
    }
}
