import QtQuick
import Quickshell

Text {
  id: dateText

  property bool expanded: false

  color: Qt.rgba(1, 1, 1, 0.8)
  font.family: "Inter"
  font.pixelSize: 12
  font.weight: Font.Medium

  opacity: expanded ? 1 : 0

  SystemClock {
      id: systemClock
      precision: SystemClock.Minutes
  }

  text: systemClock.date.toLocaleDateString(
      Qt.locale(),
      "yyyy. MM. dd."
  )

  Behavior on opacity {
      NumberAnimation {
          duration: 200
          easing.type: Easing.OutCubic
      }
  }
}
