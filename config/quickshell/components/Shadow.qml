import QtQuick
import QtQuick.Effects

Item {
  id: shadowRoot

  // 1. Publikus API property-k (kívülről vezérelhető tulajdonságok)
  property Item sourceItem: null
  property real blurAmount: 0.8
  property real verticalOffset: 6
  property color colorAmount: Qt.rgba(0, 0, 0, 1.0)

  // A konténer mérete mindig igazodjon a forrás elemhez
  width: sourceItem ? sourceItem.width : 0
  height: sourceItem ? sourceItem.height : 0

  //2. A tényleges Qt6 árnyék Effekt 
  MultiEffect {
      anchors.fill: parent

      // Melyik elemre tegye az árnyékot?
      source: shadowRoot.sourceItem

      // Árnyék tulajdonságok beállítása
      shadowEnabled: true
      shadowColor: shadowRoot.colorAmount
      shadowBlur: shadowRoot.blurAmount
      shadowVerticalOffset: shadowRoot.verticalOffset
      shadowHorizontalOffset: 0
    }

}
