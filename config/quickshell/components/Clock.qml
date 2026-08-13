import QtQuick
import Quickshell

Text {
  id: clockText

  // Vizuális beállítások
  color: "white"
  font.family: "Inter"
  font.pixelSize: 16
  font.bold: true

  // Quickshell óra szervíz
  SystemClock {
      id: systemClock
      precision: SystemClock.Minutes
  }

  // Szöveg formázása: 24 órás formátum
  text: systemClock.date.toLocaleTimeString(
      Qt.locale(),
      "HH:mm"
  )

}
