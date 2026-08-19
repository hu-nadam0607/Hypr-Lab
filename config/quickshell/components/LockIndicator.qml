import QtQuick

Item {
    id: root

    property string symbol: "A"
    property bool active: false
    property color accentColor: "#68787D"

    width: 24
    height: 28

    Rectangle {
        anchors.centerIn: parent
        width: 22
        height: 22
        radius: 7

        color: root.active
               ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.14)
               : Qt.rgba(1, 1, 1, 0.025)

        border.width: 1
        border.color: root.active
                      ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.58)
                      : Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.16)

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: root.symbol
            color: root.active
                   ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.98)
                   : Qt.rgba(1, 1, 1, 0.36)
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: root.symbol.length > 1 ? 9 : 12
            font.bold: true

            Behavior on color { ColorAnimation { duration: 120 } }
        }
    }
}
