import QtQuick

Item {
    id: timeBlockRoot

    property bool expanded: false

    anchors.fill: parent

    Clock {
        id: clockItem
        anchors.horizontalCenter: parent.horizontalCenter
        y: 10
    }

    Date {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: clockItem.bottom
        anchors.topMargin: 4
        expanded: timeBlockRoot.expanded
    }
}
