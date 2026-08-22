import QtQuick

Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property bool checked: false
    property bool enabled: true
    property color accentColor: "#68787D"

    signal toggled(bool value)

    height: 66
    opacity: enabled ? 1 : 0.42

    Column {
        anchors.left: parent.left
        anchors.right: switchTrack.left
        anchors.rightMargin: 24
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Text {
            width: parent.width
            text: root.title
            color: Qt.rgba(1, 1, 1, 0.88)
            font.family: "Inter"
            font.pixelSize: 11
            font.bold: true
            font.italic: true
        }

        Text {
            width: parent.width
            text: root.subtitle
            color: Qt.rgba(1, 1, 1, 0.38)
            font.family: "Inter"
            font.pixelSize: 8
            font.italic: true
            wrapMode: Text.WordWrap
        }
    }

    Item {
        id: switchTrack
        width: 48
        height: 24
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            anchors.fill: parent
            radius: 2
            color: root.checked
                ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.22)
                : Qt.rgba(1, 1, 1, 0.045)
            border.width: 1
            border.color: root.checked
                ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.82)
                : Qt.rgba(1, 1, 1, 0.14)

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }
        }

        Rectangle {
            width: 16
            height: 16
            radius: 1
            y: 4
            x: root.checked ? parent.width - width - 4 : 4
            color: root.checked ? root.accentColor : Qt.rgba(1, 1, 1, 0.48)

            Behavior on x {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.enabled
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.toggled(!root.checked)
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Qt.rgba(1, 1, 1, 0.055)
    }
}
