import QtQuick

Rectangle {
    id: powerBtnRoot

    signal clicked()

    width: 21
    height: 21

    radius: width / 2

    color:
        mouseArea.containsMouse
        ? Qt.rgba(255 / 255, 80 / 255, 80 / 255, 0.22)
        : Qt.rgba(1, 1, 1, 0.075)

    border.width: 1

    border.color:
        mouseArea.containsMouse
        ? Qt.rgba(255 / 255, 100 / 255, 100 / 255, 0.48)
        : Qt.rgba(1, 1, 1, 0.14)

    Behavior on color {
        ColorAnimation {
            duration: 130
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: 130
        }
    }

    Text {
        anchors.centerIn: parent

        text: "⏻"

        color:
            mouseArea.containsMouse
            ? "#ff7777"
            : "white"

        font.pixelSize: 25
        font.bold: true
    }

    property alias mouseArea: mouseArea

    MouseArea {
        id: mouseArea

        anchors.fill: parent

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            powerBtnRoot.clicked()
        }
    }
}
