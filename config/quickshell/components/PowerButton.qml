import QtQuick

Rectangle {
    id: powerBtnRoot

    // ============================================================
    // PUBLIC API
    // ============================================================

    signal clicked()

    // ============================================================
    // SIZE
    // ============================================================

    // Szinte körülöleli a 18 px-es ikont
    width: 21
    height: 21

    // Szabályos kör
    radius: width / 2

    // ============================================================
    // BACKGROUND
    // ============================================================

    color:
        mouseArea.containsMouse
        ? Qt.rgba(255 / 255, 80 / 255, 80 / 255, 0.22)
        : Qt.rgba(1, 1, 1, 0.075)

    border.width: 1

    border.color:
        mouseArea.containsMouse
        ? Qt.rgba(255 / 255, 100 / 255, 100 / 255, 0.48)
        : Qt.rgba(1, 1, 1, 0.14)

    // ============================================================
    // ANIMATIONS
    // ============================================================

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

    // ============================================================
    // POWER ICON
    // ============================================================

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

    // ============================================================
    // MOUSE
    // ============================================================

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