import QtQuick
import Quickshell
import Quickshell.Widgets

Rectangle {
    id: root

    required property var app
    required property int itemIndex
    property bool selected: false

    signal activated()

    width: ListView.view ? ListView.view.width : 672
    height: 66
    radius: 17

    color: selected
        ? Qt.rgba(18 / 255, 62 / 255, 68 / 255, 0.64)
        : mouseArea.containsMouse
            ? Qt.rgba(20 / 255, 31 / 255, 40 / 255, 0.64)
            : Qt.rgba(14 / 255, 20 / 255, 28 / 255, 0.30)

    border.width: selected ? 1 : 0
    border.color: Qt.rgba(55 / 255, 245 / 255, 235 / 255, selected ? 0.42 : 0.0)

    scale: selected ? 1.0 : 0.985

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    Behavior on scale {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: selectionGlow
        anchors.fill: parent
        anchors.margins: -2
        radius: root.radius + 2
        color: "transparent"
        border.width: root.selected ? 1 : 0
        border.color: Qt.rgba(55 / 255, 245 / 255, 235 / 255, root.selected ? 0.18 : 0.0)
        opacity: root.selected ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 160 }
        }
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 18
        spacing: 16

        Item {
            width: 42
            height: parent.height

            Rectangle {
                anchors.centerIn: parent
                width: 40
                height: 40
                radius: 13
                color: Qt.rgba(255 / 255, 255 / 255, 255 / 255, 0.055)
                border.width: 1
                border.color: Qt.rgba(255 / 255, 255 / 255, 255 / 255, 0.06)

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 27
                    source: Quickshell.iconPath(root.app.icon, "application-x-executable")
                    asynchronous: true
                }
            }
        }

        Column {
            width: parent.width - 42 - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Text {
                width: parent.width
                text: root.app.name
                color: root.selected ? "#f5ffff" : "#e0e0e0"
                font.family: "Inter"
                font.pixelSize: 14
                font.weight: root.selected ? Font.DemiBold : Font.Medium
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: root.app.genericName !== ""
                    ? root.app.genericName
                    : root.app.comment
                visible: text !== ""
                color: Qt.rgba(210 / 255, 225 / 255, 230 / 255, root.selected ? 0.72 : 0.48)
                font.family: "Inter"
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: {
            if (ListView.view)
                ListView.view.currentIndex = root.itemIndex
        }

        onClicked: root.activated()
    }
}
