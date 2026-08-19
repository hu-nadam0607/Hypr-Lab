import QtQuick

Item {
    id: root
    property string title: ""
    property string subtitle: ""
    property string valueText: ""
    property color accentColor: "#68787D"
    signal decrease()
    signal increase()
    width: parent ? parent.width : 380
    height: 52

    Column {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - 150
        spacing: 2
        Text { width: parent.width; text: root.title; color: Qt.rgba(1,1,1,0.82); font.family:"Inter"; font.pixelSize:10; font.bold:true; font.italic:true; elide:Text.ElideRight }
        Text { width: parent.width; text: root.subtitle; color: Qt.rgba(1,1,1,0.38); font.family:"Inter"; font.pixelSize:8; font.italic:true; elide:Text.ElideRight }
    }

    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        Text {
            text: "−"; color: decMouse.containsMouse ? root.accentColor : Qt.rgba(1,1,1,0.58)
            font.family:"Inter"; font.pixelSize:16; font.bold:true
            MouseArea { id:decMouse; anchors.fill:parent; anchors.margins:-8; hoverEnabled:true; cursorShape:Qt.PointingHandCursor; onClicked:root.decrease() }
        }
        Text { text: root.valueText; color: root.accentColor; font.family:"Inter"; font.pixelSize:10; font.bold:true; font.italic:true; width:58; horizontalAlignment:Text.AlignHCenter }
        Text {
            text: "+"; color: incMouse.containsMouse ? root.accentColor : Qt.rgba(1,1,1,0.58)
            font.family:"Inter"; font.pixelSize:16; font.bold:true
            MouseArea { id:incMouse; anchors.fill:parent; anchors.margins:-8; hoverEnabled:true; cursorShape:Qt.PointingHandCursor; onClicked:root.increase() }
        }
    }

    Rectangle { anchors.left:parent.left; anchors.right:parent.right; anchors.bottom:parent.bottom; height:1; color:Qt.rgba(root.accentColor.r,root.accentColor.g,root.accentColor.b,0.16) }
}
