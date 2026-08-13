import QtQuick
import Quickshell

Text {
  id: dateText

  // Nyilvános APIk
  property bool expanded: false 

  //Vizuális beállítások
  color: Qt.rgba(1, 1, 1, 0.8) // Enyhén törtfehér, hogy az óra domináljon
  font.family: "Inter"
  font.pixelSize: 12
  font.weight: Font.Medium


  // Láthatóság: ha expanded = true -> opacity = 1, különben opacity = 0
  opacity: expanded ? 1 : 0

  // Quickshell óra szervíz a dátum eléréséhez 
  SystemClock {
      id: systemClock 
      precision: SystemClock.Minutes
  }

  // Dátum formázása
  text: systemClock.date.toLocaleDateString(
      Qt.locale(),
      "yyyy. MM. dd."
  )

  // Finom átmenet az átlátszóság váltoásakor -250ms alatt- 
  Behavior on opacity {
      NumberAnimation {
          duration: 200
          easing.type: Easing.OutCubic
      }

  }

}
