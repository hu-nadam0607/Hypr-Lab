import QtQuick

Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property string valueText: ""
    property bool enabled: true
    property color accentColor: "#68787D"

    signal decrease()
    signal increase()

    height: 66
    opacity: enabled ? 1 : 0.42

    Column {
        anchors.left: parent.left
        anchors.right: controls.left
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
        }
    }

    Row {
        id: controls
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Item {
            width: 30
            height: 28
            Rectangle {
                anchors.fill: parent
                radius: 2
                color: minusMouse.containsMouse ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.12) : Qt.rgba(1,1,1,0.035)
                border.width: 1
                border.color: minusMouse.containsMouse ? root.accentColor : Qt.rgba(1,1,1,0.12)
            }
            Text { anchors.centerIn: parent; text: "−"; color: Qt.rgba(1,1,1,0.72); font.family:"Inter"; font.pixelSize:14 }
            MouseArea { id: minusMouse; anchors.fill: parent; enabled: root.enabled; hoverEnabled: true; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: root.decrease() }
        }

        Text {
            width: 72
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignHCenter
            text: root.valueText
            color: root.enabled ? root.accentColor : Qt.rgba(1,1,1,0.36)
            font.family: "JetBrains Mono"
            font.pixelSize: 10
            font.bold: true
        }

        Item {
            width: 30
            height: 28
            Rectangle {
                anchors.fill: parent
                radius: 2
                color: plusMouse.containsMouse ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.12) : Qt.rgba(1,1,1,0.035)
                border.width: 1
                border.color: plusMouse.containsMouse ? root.accentColor : Qt.rgba(1,1,1,0.12)
            }
            Text { anchors.centerIn: parent; text: "+"; color: Qt.rgba(1,1,1,0.72); font.family:"Inter"; font.pixelSize:14 }
            MouseArea { id: plusMouse; anchors.fill: parent; enabled: root.enabled; hoverEnabled: true; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: root.increase() }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Qt.rgba(1,1,1,0.055)
    }
}
