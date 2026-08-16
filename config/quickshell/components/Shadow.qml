import QtQuick
import QtQuick.Effects

Item {
  id: shadowRoot

  property Item sourceItem: null
  property real blurAmount: 0.8
  property real verticalOffset: 6
  property color colorAmount: Qt.rgba(0, 0, 0, 1.0)

  width: sourceItem ? sourceItem.width : 0
  height: sourceItem ? sourceItem.height : 0

  MultiEffect {
      anchors.fill: parent

      source: shadowRoot.sourceItem

      shadowEnabled: true
      shadowColor: shadowRoot.colorAmount
      shadowBlur: shadowRoot.blurAmount
      shadowVerticalOffset: shadowRoot.verticalOffset
      shadowHorizontalOffset: 0
    }
}
