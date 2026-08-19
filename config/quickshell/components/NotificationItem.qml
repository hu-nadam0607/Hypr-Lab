import QtQuick
import Quickshell.Widgets

Item {
    id: root
    property var notification: null
    property color accentColor: "#68787D"
    signal dismissRequested()
    implicitWidth: 320
    implicitHeight: 70
    width: implicitWidth
    height: implicitHeight

    Rectangle {
        anchors.fill: parent
        radius: 2
        color: hover.hovered ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.10) : Qt.rgba(1,1,1,0.045)
        border.width: 1
        border.color: hover.hovered ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.62) : Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.20)
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }
    }

    HoverHandler { id: hover }

    Row {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 10

        Rectangle {
            width: 34; height: 34; radius: 2
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.rgba(1,1,1,0.06)
            IconImage { anchors.centerIn: parent; width: 19; height: 19; source: root.notification ? root.notification.appIcon : "" }
        }

        Column {
            width: parent.width - 34 - (hover.hovered ? 34 : 0) - 28
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text { width: parent.width; text: root.notification ? (root.notification.appName || "Értesítés") : ""; color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.85); font.family: "Inter"; font.pixelSize: 8; font.italic: true; elide: Text.ElideRight }
            Text { width: parent.width; text: root.notification ? root.notification.summary : ""; color: "white"; font.family: "Inter"; font.pixelSize: 10; font.bold: true; font.italic: true; elide: Text.ElideRight }
            Text { width: parent.width; visible: root.notification && root.notification.body !== ""; text: root.notification ? root.notification.body : ""; textFormat: Text.PlainText; color: Qt.rgba(1,1,1,0.58); font.family: "Inter"; font.pixelSize: 8; font.italic: true; maximumLineCount: 1; elide: Text.ElideRight }
        }

        Item {
            width: hover.hovered ? 28 : 0
            height: 28
            anchors.verticalCenter: parent.verticalCenter
            visible: hover.hovered
            Behavior on width { NumberAnimation { duration: 120 } }
            Text { anchors.centerIn: parent; text: "×"; color: closeMouse.containsMouse ? root.accentColor : Qt.rgba(1,1,1,0.62); font.family: "Inter"; font.pixelSize: 16; font.bold: true }
            MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.dismissRequested() }
        }
    }
}
