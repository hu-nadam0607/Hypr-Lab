import QtQuick

Text {
    property color accentColor: "#68787D"
    height: 28
    verticalAlignment: Text.AlignVCenter
    color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.78)
    font.family: "Inter"
    font.pixelSize: 8
    font.bold: true
    font.italic: true
    font.letterSpacing: 1.3
}
