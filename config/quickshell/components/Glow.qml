import QtQuick
import QtQuick.Effects

Item {
    id: glowRoot

    property Item sourceItem: null
    property real glowBlur: 1.0
    property color glowColor: Qt.rgba(55 / 255, 245 / 255, 235 / 255, 0.25)

    width: sourceItem ? sourceItem.width : 0
    height: sourceItem ? sourceItem.height : 0

    MultiEffect {
        anchors.fill: parent

        source: glowRoot.sourceItem

        blurEnabled: true
        blurMax: 32
        blur: glowRoot.glowBlur

        colorization: 1.0
        colorizationColor: glowRoot.glowColor
    }
}
