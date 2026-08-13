import QtQuick

Item {
    id: root
    property string title: "SETTINGS"
    property string subtitle: ""
    signal backRequested()
    signal closeRequested()
    implicitHeight: 46

    Rectangle {
        id: back
        width: 38; height: 34; radius: 17
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        color: backMouse.containsMouse ? Qt.rgba(55/255,245/255,235/255,0.16) : Qt.rgba(1,1,1,0.075)
        border.width: 1
        border.color: backMouse.containsMouse ? Qt.rgba(55/255,245/255,235/255,0.55) : Qt.rgba(1,1,1,0.16)
        Text { anchors.centerIn: parent; text: "󰁍"; color: "#37f5eb"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18 }
        MouseArea { id: backMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.backRequested() }
    }
    Column {
        anchors.left: back.right; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter
        Text { text: root.title; color: "#e7f1f2"; font.family: "Inter"; font.pixelSize: 13; font.bold: true; font.letterSpacing: 1.2 }
        Text { text: root.subtitle; color: Qt.rgba(1,1,1,0.42); font.family: "Inter"; font.pixelSize: 9 }
    }
    Text {
        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
        text: "󰅖"; color: closeMouse.containsMouse ? "#37f5eb" : Qt.rgba(1,1,1,0.5)
        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18
        MouseArea { id: closeMouse; anchors.fill: parent; anchors.margins: -10; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.closeRequested() }
    }
}
