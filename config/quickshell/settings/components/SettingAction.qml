import QtQuick

Item {
    id: root
    property string title: ""
    property string subtitle: ""
    property string buttonText: "OPEN"
    property string icon: ""
    property bool enabled: true
    property color accentColor: "#68787D"
    signal triggered()

    height: 66
    opacity: enabled ? 1 : 0.42

    Row {
        anchors.left: parent.left
        anchors.right: actionButton.left
        anchors.rightMargin: 24
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Text {
            visible: root.icon.length > 0
            text: root.icon
            color: root.accentColor
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 15
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            width: parent.width - (root.icon.length > 0 ? 28 : 0)
            spacing: 3
            Text { width:parent.width; text:root.title; color:Qt.rgba(1,1,1,0.88); font.family:"Inter"; font.pixelSize:11; font.bold:true; font.italic:true }
            Text { width:parent.width; text:root.subtitle; color:Qt.rgba(1,1,1,0.38); font.family:"Inter"; font.pixelSize:8; font.italic:true; wrapMode:Text.WordWrap }
        }
    }

    Item {
        id: actionButton
        width: Math.max(72, label.implicitWidth + 28)
        height: 28
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            anchors.fill: parent
            radius: 2
            color: mouse.containsMouse ? Qt.rgba(root.accentColor.r,root.accentColor.g,root.accentColor.b,0.13) : Qt.rgba(1,1,1,0.035)
            border.width: 1
            border.color: mouse.containsMouse ? root.accentColor : Qt.rgba(root.accentColor.r,root.accentColor.g,root.accentColor.b,0.28)
        }
        Text { id:label; anchors.centerIn:parent; text:root.buttonText; color:root.accentColor; font.family:"Inter"; font.pixelSize:8; font.bold:true; font.italic:true; font.letterSpacing:0.6 }
        MouseArea { id:mouse; anchors.fill:parent; enabled:root.enabled; hoverEnabled:true; cursorShape:enabled?Qt.PointingHandCursor:Qt.ArrowCursor; onClicked:root.triggered() }
    }

    Rectangle { anchors.left:parent.left; anchors.right:parent.right; anchors.bottom:parent.bottom; height:1; color:Qt.rgba(1,1,1,0.055) }
}
