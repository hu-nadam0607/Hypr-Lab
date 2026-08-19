import QtQuick

Item {
    id: root
    property string title: ""
    property string subtitle: ""
    property bool checked: false
    property color accentColor: "#68787D"
    signal toggled(bool value)
    width: parent ? parent.width : 380
    height: 50

    Column {
        anchors.left:parent.left; anchors.verticalCenter:parent.verticalCenter
        width:parent.width-90; spacing:2
        Text { width:parent.width; text:root.title; color:Qt.rgba(1,1,1,0.82); font.family:"Inter"; font.pixelSize:10; font.bold:true; font.italic:true; elide:Text.ElideRight }
        Text { width:parent.width; text:root.subtitle; color:Qt.rgba(1,1,1,0.38); font.family:"Inter"; font.pixelSize:8; font.italic:true; elide:Text.ElideRight }
    }

    Item {
        width:42; height:20; anchors.right:parent.right; anchors.verticalCenter:parent.verticalCenter
        Rectangle { anchors.verticalCenter:parent.verticalCenter; width:42; height:3; color:root.checked ? Qt.rgba(root.accentColor.r,root.accentColor.g,root.accentColor.b,0.65) : Qt.rgba(1,1,1,0.18) }
        Rectangle {
            width:12; height:12; radius:6; anchors.verticalCenter:parent.verticalCenter
            x:root.checked ? parent.width-width : 0; color:root.checked ? root.accentColor : Qt.rgba(1,1,1,0.45)
            Behavior on x { NumberAnimation { duration:140; easing.type:Easing.OutCubic } }
        }
    }
    Rectangle { anchors.left:parent.left; anchors.right:parent.right; anchors.bottom:parent.bottom; height:1; color:Qt.rgba(root.accentColor.r,root.accentColor.g,root.accentColor.b,0.16) }
    MouseArea { anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor; onClicked:root.toggled(!root.checked) }
}
