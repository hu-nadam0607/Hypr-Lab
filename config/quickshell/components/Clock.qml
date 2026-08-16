import QtQuick
import Quickshell

Text {
  id: clockText

  color: "white"
  font.family: "Inter"
  font.pixelSize: 16
  font.bold: true

  SystemClock {
      id: systemClock
      precision: SystemClock.Minutes
  }

  text: systemClock.date.toLocaleTimeString(
      Qt.locale(),
      "HH:mm"
  )
}
