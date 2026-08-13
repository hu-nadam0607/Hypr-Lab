import QtQuick

Item {
    id: root

    property string symbol: "A"
    property bool active: false

    width: 24
    height: 28

    Rectangle {
        anchors.centerIn: parent
        width: 22
        height: 22
        radius: 7

        color: root.active
               ? Qt.rgba(55 / 255, 245 / 255, 235 / 255, 0.10)
               : Qt.rgba(1, 1, 1, 0.025)

        border.width: 1
        border.color: root.active
                      ? Qt.rgba(55 / 255, 245 / 255, 235 / 255, 0.42)
                      : Qt.rgba(1, 1, 1, 0.08)

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: root.symbol
            color: root.active
                   ? Qt.rgba(55 / 255, 245 / 255, 235 / 255, 0.95)
                   : Qt.rgba(1, 1, 1, 0.34)
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: root.symbol.length > 1 ? 9 : 12
            font.bold: true

            Behavior on color { ColorAnimation { duration: 120 } }
        }
    }
}
