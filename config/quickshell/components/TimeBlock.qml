import QtQuick

Item {
    id: timeBlockRoot

    // 1. Nyilvános API-k
    property bool expanded: false

    // Fixen kitölti a kapszula területét
    anchors.fill: parent

    // Óra: Nyugalmi állapotban pontosan függőlegesen és vízszintesen is középen van - 40px-es magasságnál: Y=10px körül-
    Clock {
        id: clockItem
        anchors.horizontalCenter: parent.horizontalCenter
        y: 10 // Nyugalmi 40px-es magasságnál ez teszi tökéletesen középre 
    }

    // Dátum: Az óra alatt jelenik meg finoman
    Date {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: clockItem.bottom
        anchors.topMargin: 4
        expanded: timeBlockRoot.expanded
    }
}
