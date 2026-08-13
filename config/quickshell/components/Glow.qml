import QtQuick
import QtQuick.Effects

Item {
    id: glowRoot

    // Nyilvános API-k
    property Item sourceItem: null
    property real glowBlur: 1.0
    property color glowColor: Qt.rgba(55 / 255, 245 / 255, 235 / 255, 0.25)

    // A konténer mérete a forrás elem méretét követi
    width: sourceItem ? sourceItem.width : 0
    height: sourceItem ? sourceItem.height : 0

    MultiEffect {
        anchors.fill: parent

        // A kapszula formáját használja alapul
        source: glowRoot.sourceItem

        // Elmosás -Blur- beállítása a fényhatáshoz
        blurEnabled: true 
        blurMax: 32
        blur: glowRoot.glowBlur

        // Színezés -Qt6 MultiEffects API: a colorization 1.0 bekapcsolja a teljes színezést- 
        colorization: 1.0
        colorizationColor: glowRoot.glowColor
    }
}
